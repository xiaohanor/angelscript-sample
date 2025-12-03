class USummitDarkCaveChainedBallMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	ASummitDarkCaveChainedBall Ball;

	UHazeMovementComponent MoveComp;
	USummitBallMovementData Movement;

	bool bFirstFrameWithTwoChains = true;
	bool bFirstFrameWithOneChain = true;

	FQuat InitialRotationRelativeToTargetRotationWhenChainMelted;
	FVector OneChainStartRightVector;

	float LastWallImpactTime = 0.0;
	float LastGroundImpactTime = 0.0;

	bool bHasImpactedGroundThisFrame = false;
	bool bHasImpactedWallThisFrame = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ball = Cast<ASummitDarkCaveChainedBall>(Owner);

		MoveComp = UHazeMovementComponent::Get(Ball);
		Movement = MoveComp.SetupMovementData(USummitBallMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(Ball.bIsChained)
			return false;

		if (Ball.bLandedInGoal)
			return false;

		if(Ball.AttachedChains.Num() >= 3)
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(Ball.bIsChained)
			return true;

		if (Ball.bLandedInGoal)
			return true;

		if(Ball.AttachedChains.Num() >= 3)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for(auto Player : Game::Players)
		{
			MoveComp.AddMovementIgnoresActor(this, Player);
		}

		bFirstFrameWithTwoChains = true;
		bFirstFrameWithOneChain = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			FVector HorizontalVelocity = MoveComp.HorizontalVelocity;
			FVector VerticalVelocity = MoveComp.VerticalVelocity + (MoveComp.GravityDirection * MoveComp.GravityForce * DeltaTime);

			if(MoveComp.IsOnAnyGround() || MoveComp.HasWallContact())
				HorizontalVelocity = Math::VInterpTo(HorizontalVelocity, FVector::ZeroVector, DeltaTime, Ball.HorizontalSpeedGroundDeceleration);
			
			FVector Velocity = HorizontalVelocity + VerticalVelocity;
			FVector TargetLocation = Ball.ActorLocation;
			FVector ConstrainDirection = FVector::ZeroVector;
			auto TemporalLog = TEMPORAL_LOG(Ball);

			if(!Ball.AttachedChains.IsEmpty())
			{
				if(Ball.AttachedChains.Num() == 1)
				{
					auto Chain = Ball.AttachedChains[0];
					auto ChainData = Ball.ChainData[Chain];

					FVector EstimatedTargetLocation = Ball.ActorLocation + Velocity * DeltaTime;
					FVector DirToChain = (Chain.ActorLocation - EstimatedTargetLocation).GetSafeNormal();
					ConstrainDirection += DirToChain;

					Velocity = Velocity.ConstrainToPlane(DirToChain);

					FVector ChainToTargetDelta = EstimatedTargetLocation - Chain.ActorLocation;
					float DistFromChainToTarget = ChainToTargetDelta.Size();
					if(DistFromChainToTarget < ChainData.ChainLength)
					{
						float DistanceOverMax = DistFromChainToTarget - ChainData.ChainLength;
						FVector ChainToTargetDir = ChainToTargetDelta.GetSafeNormal();
						TargetLocation -= ChainToTargetDir * DistanceOverMax;

						Ball.RotateChainsTowardsCenter(TargetLocation);

						TemporalLog
							.Value(f"{Chain}: Constrained Distance", Ball.ChainData[Chain].ChainLength)
							.Value(f"{Chain}: Distance From Chain To Target", DistFromChainToTarget)
							.Value(f"{Chain}: Distance Over Max", DistanceOverMax)
						;
					}
					TemporalLog
						.DirectionalArrow(f"{Chain}: Constrain Direction", Ball.ActorLocation, DirToChain * 2000, 10, 40, FLinearColor::White)
						.DirectionalArrow(f"{Chain}: Post Constrain Velocity", Ball.ActorLocation, Velocity, 1, 10, FLinearColor::Red)
						.DirectionalArrow(f"{Chain}: Post Constrain Velocity", Ball.ActorLocation, Velocity, 1, 10, FLinearColor::Red)
					;

					ConstrainDirection = ConstrainDirection.GetSafeNormal();
					Velocity = Velocity.ConstrainToPlane(ConstrainDirection);
					TemporalLog
						.DirectionalArrow(f"Constrain Direction", Ball.ActorLocation, ConstrainDirection * 2000, 10, 40, FLinearColor::Red)
					;

					if(bFirstFrameWithOneChain)
						OneChainStartRightVector = DirToChain.CrossProduct(FVector::DownVector);

					FQuat ChainRotation = FQuat::MakeFromZX(DirToChain, OneChainStartRightVector);
					TemporalLog.Rotation("Chain Rotation", ChainRotation, Ball.ActorLocation, 2000.0);

					if(bFirstFrameWithOneChain)
					{
						InitialRotationRelativeToTargetRotationWhenChainMelted = ChainRotation.Inverse() * Ball.MeshComp.ComponentQuat;
						bFirstFrameWithOneChain = false;
					}
					Ball.MeshComp.ComponentQuat = ChainRotation * InitialRotationRelativeToTargetRotationWhenChainMelted;

					TargetLocation += Velocity * DeltaTime;
				}
				else if(Ball.AttachedChains.Num() == 2)
				{
					auto ChainOne = Ball.AttachedChains[0];
					auto ChainOneData = Ball.ChainData[ChainOne];
					FVector ChainOneLocation = ChainOne.ActorLocation;
					float ChainOneLength = ChainOneData.ChainLength;

					auto ChainTwo = Ball.AttachedChains[1];
					auto ChainTwoData = Ball.ChainData[ChainTwo];
					FVector ChainTwoLocation = ChainTwo.ActorLocation;
					float ChainTwoLength = ChainTwoData.ChainLength;

					FVector ChainOneToTwoDelta = ChainTwoLocation - ChainOneLocation;
					FVector ChainOneToTwoDir = ChainOneToTwoDelta.GetSafeNormal();
					float DistanceBetweenChains = ChainOneToTwoDelta.Size();
					// How much of the delta is on the side of chain 1
					float H = 0.5 + (Math::Square(ChainOneLength) - Math::Square(ChainTwoLength)) / (2.0 * Math::Square(DistanceBetweenChains)); 
					FVector CircleLocation = ChainOneLocation + ChainOneToTwoDelta * H;
					float CircleRadius = Math::Sqrt(Math::Square(ChainOneLength) - Math::Square(H) * Math::Square(DistanceBetweenChains));
					FVector CircleNormal = ChainOneToTwoDir;

					FVector CircleToBallDelta = Ball.ActorLocation - CircleLocation;
					CircleToBallDelta = CircleToBallDelta.ConstrainToPlane(CircleNormal);
					FVector CircleToBallDir = CircleToBallDelta.GetSafeNormal();

					FVector CircleTangent = CircleNormal.CrossProduct(-CircleToBallDir);
					float TangentialSpeed = Velocity.DotProduct(CircleTangent);
					TangentialSpeed = Math::FInterpTo(TangentialSpeed, 0.0, DeltaTime, 0.15);

					FQuat CircleQuat = FQuat::MakeFromXY(CircleTangent, CircleNormal);
					float AngularSpeed = (TangentialSpeed / CircleRadius) * DeltaTime;
					CircleQuat *= FQuat(FVector::RightVector, -AngularSpeed);
					FTransform CircleTransform = FTransform(CircleQuat, CircleLocation);
					FTransform OffsetTransform = FTransform(FVector::DownVector * CircleRadius);
					
					TargetLocation = (OffsetTransform * CircleTransform).Location;

					TemporalLog
						.Sphere("Chain One Sphere", ChainOneLocation, ChainOneLength, FLinearColor::White, 2)
						.Sphere("Chain Two Sphere", ChainTwoLocation, ChainTwoLength, FLinearColor::White, 2)
						.Sphere("Circle Location", CircleLocation, 50, FLinearColor::Blue, 2)
						.Arrow("Delta Between chains", ChainOneLocation, ChainTwoLocation, 20, 200, FLinearColor::Purple)
						.Circle("Swing Circle", CircleLocation, CircleRadius, FRotator::MakeFromZ(CircleNormal), FLinearColor::LucBlue, 10)
						.DirectionalArrow("Circle Tangent", CircleLocation, CircleTangent * 2000.0, 20, 100, FLinearColor::Red)
						.DirectionalArrow("Circle Normal", CircleLocation, CircleNormal * 2000.0, 20, 100, FLinearColor::Green)
						.Value("Tangential Speed", TangentialSpeed)
						.Rotation("Ball Mesh rotation", Ball.MeshComp.ComponentQuat, Ball.ActorLocation, 2000.0)
						.Transform("Circle Transform", CircleTransform, 2000, 50)
					;

					FQuat ChainRotation = FQuat::MakeFromXZ(CircleTangent, -CircleToBallDir);

					if(bFirstFrameWithTwoChains)
					{
						InitialRotationRelativeToTargetRotationWhenChainMelted = ChainRotation.Inverse() * Ball.MeshComp.ComponentQuat;
						bFirstFrameWithTwoChains = false;
					}
					Ball.MeshComp.ComponentQuat = ChainRotation * InitialRotationRelativeToTargetRotationWhenChainMelted;
				}
				Ball.RotateChainsTowardsCenter(TargetLocation);
			}
			else
			{
				TargetLocation += Velocity * DeltaTime;
			}
			if (HasControl())
			{
				Movement.AddPendingImpulses();
				Movement.AddDeltaFromMoveTo(TargetLocation);
			}
			// Remote update
			else
			{
				if(MoveComp.IsInAir())
					Movement.ApplyCrumbSyncedAirMovement();
				else
					Movement.ApplyCrumbSyncedGroundMovement();
				// Ball.RotateChainsTowardsCenter(Ball.ActorLocation);
			}	

			// FHazeTraceDebugSettings DebugTrace;
			// DebugTrace.TraceColor = FLinearColor::Red;
			FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			TraceSettings.IgnoreActor(Owner);
			TraceSettings.UseSphereShape(320.0);
			// TraceSettings.DebugDraw(DebugTrace);
			FHitResultArray Hits = TraceSettings.QueryTraceMulti(Ball.ActorLocation, Ball.ActorLocation + Velocity.GetSafeNormal());

			for (FHitResult Hit : Hits)
			{
				if (Hit.bBlockingHit)
				{
					auto Player = Cast<AHazePlayerCharacter>(Hit.Actor);
					if (Player != nullptr)
					{
						FVector ImpactDir = (Player.ActorLocation - Ball.ActorLocation).GetSafeNormal();
						float Dot = ImpactDir.DotProduct(FVector::UpVector);

						if (Dot < -0.9 && Velocity.Size() > 600 && !Player.IsPlayerDead())
						{
							Player.KillPlayer();
						}

					} 
				}
			}

			HandleImpacts();

			MoveComp.ApplyMove(Movement);
		}

		if (bHasImpactedGroundThisFrame || bHasImpactedWallThisFrame)
		{
			Ball.PlayFeedback();

			bHasImpactedGroundThisFrame = false;
			bHasImpactedWallThisFrame = false;
		}
	}

	void HandleImpacts()
	{
		if (!HasControl())
			return;

		for (FMovementHitResult Hit : MoveComp.AllImpacts)
		{
			auto ResponseComp = USummitDarkCaveChainedBallResponseComponent::Get(Hit.Actor);
			if (ResponseComp != nullptr)
			{
				ResponseComp.OnBallImpact(Ball);
			}

			FVector DirToImpact = (Hit.ImpactPoint - Ball.ActorLocation).GetSafeNormal();
			float SpeedTowardsHit = MoveComp.PreviousVelocity.DotProduct(DirToImpact);
			
			if(SpeedTowardsHit < 400.0
			|| (Hit.IsAnyGroundContact() && bHasImpactedGroundThisFrame)
			|| (Hit.IsWallImpact() && bHasImpactedWallThisFrame))
				continue;

			FSummitDarkCaveChainedBallImpactParams EventParams;
			EventParams.ImpactLocation = Hit.ImpactPoint;
			EventParams.SpeedIntoImpact = SpeedTowardsHit;
			FHitResult HitResult = Hit.ConvertToHitResult();
			FHazeTraceSettings TraceSettings;
			TraceSettings.TraceWithMovementComponent(MoveComp);
			EventParams.ImpactedMaterial = AudioTrace::GetPhysMaterialFromHit(HitResult, TraceSettings);

			if(Hit.IsAnyGroundContact())
			{
				if (LastGroundImpactTime == 0.0 || Time::GetRealTimeSince(LastGroundImpactTime) > 0.25)
				{
					CrumbBallImpact(EventParams, true);
				}
			}	
			else if(Hit.IsWallImpact())
			{
				if (LastWallImpactTime == 0.0 || Time::GetRealTimeSince(LastWallImpactTime) > 0.25)
				{
					CrumbBallImpact(EventParams, false);
				}
			}
		} 
	}

	UFUNCTION(CrumbFunction)
	void CrumbBallImpact(FSummitDarkCaveChainedBallImpactParams ImpactParams, bool bIsGroundImpact)
	{
		if(bIsGroundImpact)
		{
			USummitDarkCaveChainedBallEventHandler::Trigger_OnBallImpactedGround(Ball, ImpactParams);
			LastGroundImpactTime = Time::RealTimeSeconds;
			bHasImpactedGroundThisFrame = true;
		}	
		else
		{
			USummitDarkCaveChainedBallEventHandler::Trigger_OnBallImpactedWall(Ball, ImpactParams);
			LastWallImpactTime = Time::RealTimeSeconds;
			bHasImpactedWallThisFrame = true;
		}
	}
};