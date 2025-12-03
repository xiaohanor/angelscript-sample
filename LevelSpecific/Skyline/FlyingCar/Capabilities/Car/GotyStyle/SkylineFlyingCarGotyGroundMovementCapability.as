class USkylineFlyingCarGotyGroundMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(FlyingCarTags::FlyingCarMovement);
	default CapabilityTags.Add(FlyingCarTags::FlyingCarGroundMovement);

	// Must activate before FreeMovement capability
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 89;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ASkylineFlyingCar CarOwner;

	UHazeMovementComponent MovementComponent;
	USkylineFlyingCarMovementData MoveData;
	USkylineFlyingCarGotySettings Settings;

	UHazeCrumbSyncedFloatComponent CrumbedYawAngle;

	float GroundlessTimer;

	FVector RelativeMeshOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CarOwner = Cast<ASkylineFlyingCar>(Owner);
		MovementComponent = UHazeMovementComponent::Get(Owner);
		MoveData = MovementComponent.SetupMovementData(USkylineFlyingCarMovementData);
		Settings = USkylineFlyingCarGotySettings::GetSettings(Owner);

		CrumbedYawAngle = UHazeCrumbSyncedFloatComponent::GetOrCreate(Owner, n"FlyingCarGroundMovementYaw");
		CrumbedYawAngle.OverrideSyncRate(EHazeCrumbSyncRate::High);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MovementComponent.HasMovedThisFrame())
			return false;

		if (CarOwner.Pilot == nullptr)
			return false;

		USkylineFlyingCarPilotComponent PilotComponent = USkylineFlyingCarPilotComponent::Get(CarOwner.Pilot);
		if (PilotComponent == nullptr)
			return false;

		// if (!PilotComponent.IsInsideGroundMovementZone())
		// 	return false

		if (!FlyingCar::IsOnSlidingGround(MovementComponent))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MovementComponent.HasMovedThisFrame())
			return true;

		if (CarOwner.Pilot == nullptr)
			return true;

		USkylineFlyingCarPilotComponent PilotComponent = USkylineFlyingCarPilotComponent::Get(CarOwner.Pilot);
		if (PilotComponent == nullptr)
			return true;

		// if (!PilotComponent.IsInsideGroundMovementZone())
		// 	return true;

		// if (!MovementComponent.IsOnAnyGround())
		if (GroundlessTimer >= 0.2)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GroundlessTimer = 0.0;

		// Add bouncy impulse
		FVector Horizontal = MovementComponent.PreviousVelocity.ConstrainToPlane(CarOwner.MovementWorldUp);
		FVector Vertical = (-MovementComponent.PreviousVelocity.ConstrainToDirection(CarOwner.MovementWorldUp) * Settings.CrashBounceImpulseMultiplier).GetClampedToMaxSize(1600.0);
		FVector Bounce = -Horizontal * 0.2 + Vertical;
		// CarOwner.AddMovementImpulse(Bounce); // Eman TODO: Handle bounce as mesh-only

		RelativeMeshOffset = CarOwner.MeshRoot.RelativeLocation;

		UMovementGravitySettings::SetGravityAmount(CarOwner, Settings.GravityAmount, this);

		CrumbedYawAngle.Value = 0.0;

		// Play one shot
		CarOwner.Pilot.PlayCameraShake(CarOwner.LightCollisionCameraShake, this, 2.5);

		// Play looping shake
		CarOwner.Pilot.PlayCameraShake(CarOwner.GroundMovementCameraShake, this);

		// Add camera settings instead!
		const float BlendTime = 1.;
		UCameraSettings CameraSettings = UCameraSettings::GetSettings(CarOwner.Pilot);
		CameraSettings.FOV.Apply(100, this, BlendTime, SubPriority = 61);
		CameraSettings.CameraOffset.Apply(-FVector::UpVector * 300, this, BlendTime, SubPriority = 61);
		CameraSettings.IdealDistance.Apply(600, this, BlendTime, EHazeCameraPriority::Medium, SubPriority = 61);

		USkylineFlyingCarEventHandler::Trigger_OnStartGroundedMovement(CarOwner);

		SpeedEffect::RequestSpeedEffect(CarOwner.Pilot, 0.3, this, EInstigatePriority::Normal, 0.5);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMovementGravitySettings::ClearGravityAmount(CarOwner, this);
		CarOwner.Pilot.ClearCameraSettingsByInstigator(this, 2.0);

		if (CarOwner.Pilot != nullptr)
		{
			USkylineFlyingCarPilotComponent PilotComponent = USkylineFlyingCarPilotComponent::Get(CarOwner.Pilot);
			if (PilotComponent != nullptr)
			{
				PilotComponent.bWasGroundMoving = true;
			}
		}

		USkylineFlyingCarEventHandler::Trigger_OnStopGroundedMovement(CarOwner);

		SpeedEffect::ClearSpeedEffect(CarOwner.Pilot, this);

		CarOwner.MeshOffset.ResetOffsetWithLerp(this, 0.2);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			// Gotta update value before calculating course vector
			if (HasControl())
				CrumbedYawAngle.Value = Math::FInterpTo(CrumbedYawAngle.Value, CarOwner.YawInput * 15.0, DeltaTime, 3.0);

			// Get course vector which will be slightly ahead of actual velocity to get a drifty feel
			FVector Course = MovementComponent.Velocity.GetSafeNormal().RotateAngleAxis(CrumbedYawAngle.Value, CarOwner.MovementWorldUp).GetSafeNormal();

			if (HasControl())
			{
				const float InterpSpeed = 10.;
				float Speed = Math::FInterpTo(MovementComponent.Velocity.Size(), Settings.CrashMoveSpeed, DeltaTime, InterpSpeed);
				FVector Velocity = MovementComponent.Velocity.GetSafeNormal().RotateTowards(Course, InterpSpeed * DeltaTime).GetSafeNormal() * Speed;
				MoveData.AddVelocity(Velocity);

				MoveData.AddGravityAcceleration();
				MoveData.AddPendingImpulses();

				FQuat Rotation = Velocity.ToOrientationQuat();
				if (MovementComponent.IsOnAnyGround())
					Rotation = Velocity.ConstrainToPlane(CarOwner.ActorUpVector).ToOrientationQuat();

				// Rotation = Math::QInterpConstantTo(CarOwner.ActorQuat, Rotation, DeltaTime, 20.0);
				Rotation = MovementComponent.Velocity.ConstrainToPlane(CarOwner.MovementWorldUp).ToOrientationQuat();
				MoveData.SetRotation(Rotation);
			}
			else
			{
				MoveData.ApplyCrumbSyncedGroundMovement();
			}

			MovementComponent.ApplyMove(MoveData);

			// Handle mesh rotation
			FRotator TargetMeshRotation = Course.Rotation();
			CarOwner.CrumbedMeshRotation.Value = Math::RInterpTo(CarOwner.CrumbedMeshRotation.Value, TargetMeshRotation, DeltaTime, 10.0);
			CarOwner.MeshRoot.WorldRotation = CarOwner.CrumbedMeshRotation.Value;

			float MeshOffsetAlpha = Math::Square(Math::Saturate(ActiveDuration / 0.3));

			// Add wobble and lower pitch by 10 degrees, otherwise car looks stupid
			const float Intensity = 7.0;
			FRotator PitchFix = FRotator(10, 0, 0);
			FRotator TargetWobble = FRotator(Math::PerlinNoise1D(Time::GameTimeSeconds * 2.153) * Intensity, Math::PerlinNoise1D(Time::GameTimeSeconds * 5.42), Math::PerlinNoise1D(Time::GameTimeSeconds * 4.421) * Intensity);

			FQuat Wobble = FQuat::FastLerp(FQuat::Identity, TargetWobble.Quaternion(), MeshOffsetAlpha);
			FQuat MeshOffsetRotation = CarOwner.MeshRoot.ComponentQuat * PitchFix.Quaternion() * Wobble;

			// Push mesh downwards because of assy collision shape (that is needed for flyin')
			RelativeMeshOffset = Math::VInterpTo(RelativeMeshOffset, FVector::DownVector * CarOwner.SphereCollision.SphereRadius * 1.2, DeltaTime, 20.0);
			FVector MeshOffsetLocation = CarOwner.MeshRoot.WorldTransform.TransformPositionNoScale(RelativeMeshOffset);

			FTransform MeshOffset(MeshOffsetRotation, MeshOffsetLocation);
			CarOwner.MeshOffset.SnapToTransform(this, MeshOffset);
		}

		GroundlessTimer = FlyingCar::IsOnSlidingGround(MovementComponent) ? 0.0 : GroundlessTimer + DeltaTime;

		float CrashLanding = 1.0 - Math::Pow(Math::Saturate(ActiveDuration / 0.5), 3);

		// FF juice
		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::Abs(Math::PerlinNoise1D(Math::Max(0.1, Time::GameTimeSeconds * 150))) + CrashLanding;
		FF.RightMotor = Math::Abs(Math::PerlinNoise1D(Math::Max(0.1, Time::GameTimeSeconds * 200))) + CrashLanding;

		float TriggerValue = Math::Abs(Math::PerlinNoise1D(Math::Max(0.2, Time::GameTimeSeconds * 300))) + CrashLanding;
		FF.LeftTrigger = TriggerValue;
		FF.RightTrigger = TriggerValue;

		ForceFeedback::PlayWorldForceFeedbackForFrame(FF, CarOwner.ActorLocation, 1000, 1000);
	}
}