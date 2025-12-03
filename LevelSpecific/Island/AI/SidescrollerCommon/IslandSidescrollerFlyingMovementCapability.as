class UIslandSidescrollerFlyingMovementCapability : UHazeCapability
{	
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"FlyingMovement");	

	default TickGroup = EHazeTickGroup::ActionMovement;

	default DebugCategory = CapabilityTags::Movement;

	EMovementDeltaType RemoteMovementDeltaType = EMovementDeltaType::Native;
	
	UPathfollowingSettings PathingSettings;
	UBasicAIMovementSettings MoveSettings;
	UBasicAICharacterMovementComponent MoveComp;
	UBasicAIDestinationComponent DestinationComp;
	UHazeCrumbSyncedActorPositionComponent CrumbMotionComp;
	UBasicAIAnimationComponent AnimComp;
	
	UBaseMovementData Movement;
	
    FVector CustomVelocity;
	FVector PrevLocation;
	
	USimpleMovementData SlidingMovement;

	UPathfollowingMoveToComponent PathFollowingComp;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);
		MoveSettings = UBasicAIMovementSettings::GetSettings(Owner);
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);		
		CrumbMotionComp = UHazeCrumbSyncedActorPositionComponent::GetOrCreate(Owner); // This has to be created before MoveComp runs BeginPlay
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);

		Movement = MoveComp.SetupSimpleMovementData();
		SlidingMovement = Cast<USimpleMovementData>(Movement);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (DestinationComp.FollowSpline != nullptr)
			return;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!Player.IslandIsInSidescrollerMode())
				continue;
			
			UPlayerSplineLockComponent SplineLockComp = UPlayerSplineLockComponent::Get(Player);
			if (SplineLockComp == nullptr)
				continue;

			if (SplineLockComp.InstigatedSettings.Get().Spline != nullptr)
			{
				DestinationComp.FollowSpline = SplineLockComp.InstigatedSettings.Get().Spline;
				break;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DestinationComp.FollowSpline == nullptr)
			return false;
		if (DestinationComp.bHasPerformedMovement)
			return false;
        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DestinationComp.FollowSpline == nullptr)
			return true;
		if (DestinationComp.bHasPerformedMovement)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{		
		MoveComp.AccRotation.SnapTo(Owner.ActorRotation);
		PrevLocation = Owner.ActorLocation;		

		if (HasControl())
		{
			// DestinationComp.FollowSpline might be null on remote, but these values are only used on control side
			float DistAlongSpline = DestinationComp.FollowSpline.GetClosestSplineDistanceToWorldLocation(Owner.ActorLocation);
			DestinationComp.FollowSplinePosition = FSplinePosition(DestinationComp.FollowSpline, DistAlongSpline, true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(!MoveComp.PrepareMove(SlidingMovement))
			return;

		if(HasControl())
		{
			ComposeMovement(DeltaTime);
		}
		else
		{
			// Since we normally don't want to replicate velocity, we use move since last frame instead.
			// This can fluctuate wildly, introduce smoothing/velocity replication if necessary
			FVector Velocity = (DeltaTime > 0.0) ? (Owner.ActorLocation - PrevLocation) / DeltaTime : Owner.ActorVelocity;			
			Movement.ApplyCrumbSyncedGroundMovementWithCustomVelocity(Velocity);
			PrevLocation = Owner.ActorLocation;
		}

		MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimComp.FeatureTag);
		DestinationComp.bHasPerformedMovement = true;
	}

	void ComposeMovement(float DeltaTime)
	{	
		FVector OwnLoc = Owner.ActorLocation;
		FVector Destination = DestinationComp.Destination;

		FVector ToDest = (Destination - OwnLoc);
		float DestDist = ToDest.Size();
		FVector DestDir = (DestDist > 1.0) ? ToDest / DestDist : Owner.ActorForwardVector;
		float MoveDir = Math::Sign(DestinationComp.FollowSplinePosition.WorldForwardVector.DotProduct(Destination - OwnLoc));
		if (DestinationComp.HasDestination() && (DestDist > 1.0))
		{			
			float MoveSpeed = DestinationComp.Speed;
			DestinationComp.FollowSplinePosition.Move(MoveSpeed * DeltaTime * MoveDir);
			
			FVector TargetSplinePos = DestinationComp.FollowSplinePosition.WorldLocation;
			TargetSplinePos.Z = 0.0;
			FVector OwnHorizontalPos = OwnLoc;
			OwnHorizontalPos.Z = 0.0;			

			float SlowDownRadiusSqr = Math::Square(100.0);
			float RemainingHorizontalDist = TargetSplinePos.DistSquared(OwnHorizontalPos);
			float MoveSpeedScale = RemainingHorizontalDist < SlowDownRadiusSqr ? RemainingHorizontalDist / SlowDownRadiusSqr : 1.0;

			Movement.AddVelocity(DestDir * MoveSpeed * DeltaTime * MoveSpeedScale);
			
			//FVector DeltaMove = (DestinationComp.FollowSplinePosition.WorldLocation - OwnLoc);
			//DeltaMove.Z = 0.0;
			//Movement.AddDelta(DeltaMove * DeltaTime);
		}
		else
		{
			// No destination, let friction slow us to a stop 
			DestinationComp.ReportStopping();
		}

		// Apply friction
		float Friction = MoveSettings.AirFriction;
		FVector Velocity = MoveComp.Velocity;
		Velocity -= Velocity * Friction * DeltaTime;

		Movement.AddVelocity(Velocity);

		FVector ConstrainedCustomAcc = DestinationComp.FollowSplinePosition.WorldForwardVector * DestinationComp.CustomAcceleration.DotProduct(DestinationComp.FollowSplinePosition.WorldForwardVector);
		ConstrainedCustomAcc.Z = DestinationComp.CustomAcceleration.Z;

		// TODO: investigate frame rate dependency
		CustomVelocity += ConstrainedCustomAcc * DeltaTime;
		CustomVelocity -= CustomVelocity * Friction * DeltaTime;
		Movement.AddVelocity(CustomVelocity);

		// Turn towards focus or direction of move
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, MoveSettings.TurnDuration, DeltaTime, Movement);
		else if (DestinationComp.HasDestination() && !OwnLoc.IsWithinDist(Destination, PathingSettings.AtDestinationRange))
			MoveComp.RotateTowardsDirection(DestDir, MoveSettings.TurnDuration, DeltaTime, Movement);
		else  
			MoveComp.StopRotating(MoveSettings.StopTurningDamping, DeltaTime, Movement);

		Movement.AddPendingImpulses();

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(Destination, OwnLoc, FLinearColor::LucBlue);		
			Debug::DrawDebugLine(OwnLoc, OwnLoc + Velocity, FLinearColor::Green);		

			float Acc = DestinationComp.Speed;
			FVector DebugVel = Velocity; 
			float dt = 0.05;
			FVector PrevLoc = OwnLoc;
			FVector DebugLoc = OwnLoc;
			FVector StringLoc = FVector(BIG_NUMBER);
			for (float t = 0; t < 10.0 && !DebugLoc.IsWithinDist(Destination, 50.0); t += dt)
			{
				// Accelerate right/left to turn towards destination
				FVector CurDir = DebugVel.IsNearlyZero(10.0) ? Owner.ActorForwardVector : DebugVel.GetSafeNormal();
				float DestAccFactor = 1.0;
				FVector TurnCross = FVector::ZeroVector;
				if (CurDir.DotProduct(DestDir) < 1.0 - SMALL_NUMBER)
				{
					FVector TurnPlaneNormal = CurDir.CrossProduct(DestDir);
					TurnCross = TurnPlaneNormal.CrossProduct(CurDir);
					DebugVel += TurnCross * Acc * dt;
					DestAccFactor = 1.0 - TurnCross.Size();
				}

				// Accelerate directly towards destination
				DebugVel += DestDir * Acc * DestAccFactor * dt;

				DebugVel -= DebugVel * Friction * dt;
				DebugLoc += DebugVel * dt;
				Debug::DrawDebugLine(DebugLoc, DebugLoc + TurnCross * 100, FLinearColor::Yellow, 0.f);	
				Debug::DrawDebugLine(PrevLoc, DebugLoc, FLinearColor::Red);	
				if (!StringLoc.IsWithinDist(DebugLoc, 100.0))
				{
					//Debug::DrawDebugString(DebugLoc + FVector(0,0,20), "" + TurnCross.Size());
					StringLoc = DebugLoc;
				}
				PrevLoc = DebugLoc;		
				DestDir = (Destination - DebugLoc).GetSafeNormal();	
			}
		}
#endif
	}
}
