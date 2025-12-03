asset TeenDragonTailRollInStoneWaterWheelMovementSettings of UMovementStandardSettings
{
	WalkableSlopeAngle = 90.0;
}

class USummitStoneWaterWheelMoveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	ASummitStoneWaterWheel Wheel;

	UHazeMovementComponent MoveComp;
	USweepingMovementData Movement;

	AHazePlayerCharacter Zoe;

	bool bHasAppliedSettings = false;
	bool bHasPlayedLandShake = false;
	bool bIsFollowingExitSpline = false;

	FVector PreviousFrameAverageNormal;
	float PreviousFrameVelocitySize;

	float ImpactFeedbackBuffer = 0.6;
	float LastImpactFeedbackTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Wheel = Cast<ASummitStoneWaterWheel>(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSweepingMovementData();

		Zoe = Game::GetZoe();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(Wheel.bFollowExitSpline)
			return false;

		if(!Wheel.bIsActive)
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(Wheel.bFollowExitSpline)
			return true;

		if(!Wheel.bIsActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(bHasAppliedSettings)
		{
			Zoe.ClearSettingsByInstigator(this);
			bHasAppliedSettings = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector GroundNormal = MoveComp.CurrentGroundNormal;
				FVector AverageGroundNormal = GetAverageGroundNormal(GroundNormal);
				FVector Forward = PreviousFrameAverageNormal.CrossProduct(-Wheel.ActorRightVector).GetSafeNormal();

				TEMPORAL_LOG(Wheel)
					.DirectionalArrow("Forward", Wheel.ActorLocation, Forward * 500, 10, 40, FLinearColor::Red)
					.DirectionalArrow("Ground Normal", Wheel.ActorLocation, GroundNormal * 500, 10, 40, FLinearColor::Blue)
					.DirectionalArrow("Average Ground Normal", Wheel.ActorLocation, AverageGroundNormal * 500, 10, 40, FLinearColor::Blue)
				;

				TOptional<AHazePlayerCharacter> TailPlayer = GetValidGroundedRollingTailDragonInsideWheel();
				if(TailPlayer.IsSet())
				{
					if(!bHasAppliedSettings)
					{
						Zoe.ApplySettings(TeenDragonTailRollInStoneWaterWheelMovementSettings, this);
						bHasAppliedSettings = true;
					}

					AHazePlayerCharacter Player = TailPlayer.Value;

					FVector DeltaToPlayer = Player.ActorLocation - Wheel.ActorLocation;

					TEMPORAL_LOG(Wheel)
						.DirectionalArrow("Delta to Player", Wheel.ActorLocation, DeltaToPlayer, 10, 40, FLinearColor::Purple)
					;

					float DistanceForward = Forward.DotProduct(DeltaToPlayer);

					bool bIsAlignedForward = Player.ActorRotation.ForwardVector.DotProduct(Wheel.ActorForwardVector) > 0.0;
					FVector TargetPlayerForward = bIsAlignedForward ? Wheel.ActorForwardVector : -Wheel.ActorForwardVector;
					FRotator TargetRotation = TargetPlayerForward.Rotation(); 
					TargetRotation.Pitch = Player.ActorRotation.Pitch;
					TargetRotation.Roll = Player.ActorRotation.Roll;
					Player.ActorRotation = Math::RInterpTo(Player.ActorRotation, TargetRotation, DeltaTime, 20);

					Movement.AddAcceleration(Forward * DistanceForward * Wheel.PlayerWeightValue * (1.0/45.0));
				}
				else if(bHasAppliedSettings)
				{
					Zoe.ClearSettingsByInstigator(this);
					bHasAppliedSettings = false;
				}

				if(MoveComp.IsOnAnyGround())
				{
					FVector SlopeAcceleration = GetSlopeAcceleration(PreviousFrameAverageNormal, Forward, DeltaTime);
					Movement.AddVelocity(SlopeAcceleration);
				}

				FVector CurrentVelocity = MoveComp.Velocity;
				float CurrentSpeed = CurrentVelocity.Size();
				if(CurrentSpeed > Wheel.MaxSpeed)
				{
					float OverSpeed = CurrentSpeed - Wheel.MaxSpeed;
					Movement.AddVelocity(-CurrentVelocity.GetSafeNormal() * OverSpeed);
				}

				FVector DeceleratedVelocity = Math::VInterpTo(CurrentVelocity, FVector::ZeroVector, DeltaTime, Wheel.DecelerationValue);
				DeceleratedVelocity = Math::VInterpConstantTo(DeceleratedVelocity, FVector::ZeroVector, DeltaTime, Wheel.ConstantDeceleration);

				FVector Deceleration = DeceleratedVelocity - CurrentVelocity;
				Deceleration = Deceleration.GetClampedToMaxSize(CurrentVelocity.Size());

				TEMPORAL_LOG(Wheel)
					.DirectionalArrow("Velocity Dir", Wheel.ActorLocation, CurrentVelocity.GetSafeNormal() * 2000, 10, 4000, FLinearColor::Purple)
					.DirectionalArrow("Deceleration", Wheel.ActorLocation, Deceleration, 10, 4000, FLinearColor::White)
					.DirectionalArrow("Deceleration Dir", Wheel.ActorLocation, Deceleration.GetSafeNormal() * 2000, 10, 4000, FLinearColor::Gray)
				;

				Movement.AddVelocity(Deceleration);

				FRotator SpeedRotation = GetRotationFromSpeed(DeltaTime);
				Wheel.RotationRoot.AddLocalRotation(SpeedRotation);
				Wheel.SyncRotationComp.SetValue(Wheel.RotationRoot.WorldRotation);

				Movement.AddOwnerVelocity();
				Movement.AddGravityAcceleration();

				PreviousFrameAverageNormal = AverageGroundNormal;

				if(MoveComp.IsOnAnyGround()
				&& MoveComp.WasInAir()
				&& !bHasPlayedLandShake)
				{
					SceneView::FullScreenPlayer.PlayCameraShake(Wheel.LandingCameraShake, this);
					bHasPlayedLandShake = true;
					USummitStoneWaterWheelEventHandler::Trigger_OnLanded(Wheel);
				}
			}
			// Remote update
			else
			{
				Wheel.RotationRoot.SetWorldRotation(Wheel.SyncRotationComp.Value);
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			PreviousFrameVelocitySize = MoveComp.Velocity.Size(); 
			MoveComp.ApplyMove(Movement);
			float CurrentSize = MoveComp.Velocity.Size();
			float Difference = CurrentSize - PreviousFrameVelocitySize;
			PrintToScreen(f"{Difference=}");
			// PrintToScreen(f"{PreviousFrameVelocitySize=}");

			if (Difference < -600.0)
			{
				if ((Time::GameTimeSeconds - LastImpactFeedbackTime) < ImpactFeedbackBuffer)
					return;

				LastImpactFeedbackTime = Time::GameTimeSeconds;
				
				for (AHazePlayerCharacter Player : Game::Players)
				{
					Player.PlayCameraShake(Wheel.LandingCameraShake, this);
					Player.PlayForceFeedback(Wheel.ImpactRumble, false, false, this, 1.5);
				}
			}
		}
	}

	TOptional<AHazePlayerCharacter> GetValidGroundedRollingTailDragonInsideWheel() const
	{
		TOptional<AHazePlayerCharacter> TailPlayer;

		if(Zoe.ActorLocation.DistSquared(Wheel.ActorLocation) < Math::Square(Wheel.PlayerCheckRadius * Wheel.CapsuleComp.ShapeScale))
		{
			auto RollComp = UTeenDragonRollComponent::Get(Zoe);
			if(RollComp == nullptr)
				return TailPlayer;
			
			if(!RollComp.IsRolling())
				return TailPlayer;

			auto PlayerMoveComp = UPlayerMovementComponent::Get(Zoe);
			if(PlayerMoveComp.IsInAir())
				return TailPlayer;
			
			TailPlayer.Set(Zoe);
		}

		return TailPlayer;
	}

	FRotator GetRotationFromSpeed(float DeltaTime) const
	{
		FRotator Rotation;
		
		float Speed = MoveComp.HorizontalVelocity.ConstrainToPlane(Wheel.ActorRightVector).Size();
		float RotationAngle = Math::RadiansToDegrees(-Speed * DeltaTime / Wheel.CapsuleComp.CapsuleRadius);

		if(MoveComp.HorizontalVelocity.DotProduct(Wheel.ActorForwardVector) < 0)
			RotationAngle *= -1;

		Rotation = FRotator(RotationAngle, 0 , 0); 

		return Rotation;
	}	

	FVector GetSlopeAcceleration(FVector GroundNormal, FVector Forward, float DeltaTime) const
	{
		FVector SlopeAcceleration;
		float NormalDegreesFromUp = GroundNormal.GetAngleDegreesTo(FVector::UpVector);
		float GravityDotForward = MoveComp.GravityDirection.DotProduct(Forward);
		FVector AccelerationDirection = GravityDotForward > 0 
			? Forward 
			: -Forward;

		SlopeAcceleration = AccelerationDirection * NormalDegreesFromUp * Wheel.SlopeAcceleration * MoveComp.GravityForce * DeltaTime;

		TEMPORAL_LOG(Wheel)
			.DirectionalArrow("Slope Acceleration", Wheel.ActorLocation, SlopeAcceleration, 2, 10, FLinearColor::DPink)
			.DirectionalArrow("Slope Acceleration Direction", Wheel.ActorLocation, SlopeAcceleration.GetSafeNormal() * 2000, 2, 4000, FLinearColor::LucBlue)
			.Value("Normal Degrees From Up", NormalDegreesFromUp)
		;
		return SlopeAcceleration;
	}

	FVector GetAverageGroundNormal(FVector InGroundNormal) const
	{
		FVector GroundNormal = InGroundNormal;
		const int NormalTraceIterations = 5;
		const float NormalTraceDegreeIncrease = 5.0;

		for(int i = 0; i < NormalTraceIterations; i++)
		{
			FVector Start = Wheel.ActorLocation;
			FVector EstimatedGroundLocation = Start + FVector::DownVector * Wheel.CapsuleComp.ScaledCapsuleRadius;
			FVector DeltaToGround = (EstimatedGroundLocation - Start) * 1.05;
			// FVector DeltaToGround = (MoveComp.GroundContact.ImpactPoint - Start) * 1.05;
			FVector DeltaToEnd = DeltaToGround.RotateAngleAxis(NormalTraceDegreeIncrease * (i + 1), Wheel.ActorRightVector);

			FVector End = Start + DeltaToEnd;

			FHazeTraceSettings ForwardTrace;
			ForwardTrace.UseLine();
			ForwardTrace.TraceWithProfileFromComponent(Wheel.CapsuleComp);
			ForwardTrace.IgnoreActor(Wheel);
			ForwardTrace.IgnorePlayers();
			auto Hit = ForwardTrace.QueryTraceSingle(Start, End);

			if(Hit.bBlockingHit)
			{
				GroundNormal += Hit.ImpactNormal;
			}

			TEMPORAL_LOG(Wheel, "Ground Trace")
				.HitResults(f"{i}: Foward Trace", Hit, FHazeTraceShape::MakeLine())
				// .Sphere(f"{i}: Foward Trace: Start", Start, 50, FLinearColor::Red, 5)
				// .DirectionalArrow(f"{i}: Foward Trace: DeltaToEnd", Wheel.ActorLocation, DeltaToEnd, 5, 10, FLinearColor::Red)
				// .Sphere(f"{i}: Foward Trace: End", End, 50, FLinearColor::Red, 5)
			;

			DeltaToEnd = DeltaToGround.RotateAngleAxis(-NormalTraceDegreeIncrease * (i + 1), Wheel.ActorRightVector);
			End = Start + DeltaToEnd;

			FHazeTraceSettings BackwardsTrace;
			BackwardsTrace.UseLine();
			BackwardsTrace.TraceWithProfileFromComponent(Wheel.CapsuleComp);
			BackwardsTrace.IgnoreActor(Wheel);
			BackwardsTrace.IgnorePlayers();
			Hit = ForwardTrace.QueryTraceSingle(Start, End);

			if(Hit.bBlockingHit)
			{
				GroundNormal += Hit.ImpactNormal;
			}

			TEMPORAL_LOG(Wheel, "Ground Trace")
				.HitResults(f"{i}: Backward Trace", Hit, FHazeTraceShape::MakeLine())
				// .Sphere(f"{i}: Backward Trace: Start", Start, 50, FLinearColor::Red, 5)
				// .DirectionalArrow(f"{i}: Backward Trace: DeltaToEnd", Wheel.ActorLocation, DeltaToEnd, 5, 10, FLinearColor::Red)
				// .Sphere(f"{i}: Backward Trace: End", End, 50, FLinearColor::Red, 5)
			;
		}

		GroundNormal = GroundNormal.GetSafeNormal();
	
		return GroundNormal;
	}

};