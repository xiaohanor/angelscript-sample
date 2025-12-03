struct FSkylineFlyingCarGotySplineRampMovementCapabilityDeactivationParams
{
	bool bReachedEndOfSpline = false;
}

class USkylineFlyingCarGotySplineRampMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(FlyingCarTags::FlyingCarMovement);

	// Tick before normal movement and ramp jump
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 88;

	default DebugCategory = n"FlyingCar";

	ASkylineFlyingCar Car;
	USkylineFlyingCarGotySettings Settings;

	UHazeMovementComponent MovementComponent;
	USkylineFlyingCarMovementData MoveData;

	FRotator PreviousMeshRotation = FRotator::ZeroRotator;

	bool bReachedEndOfRampSpline = false;
	float MoveSpeed = 0.0;

	ASkylineFlyingCarHighwayRamp HighwayRamp = nullptr;

	FHazeAcceleratedVector AcceleratedInput;
	FHazeAcceleratedFloat AcceleratedHeightSpeed;

	float PreviousHorizontalSpeed;

	bool bPullUpMode = true;
	bool bSteepClimbing = false;

	bool bBoosting = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Car = Cast<ASkylineFlyingCar>(Owner);
		Settings = USkylineFlyingCarGotySettings::GetSettings(Owner);
		MovementComponent = UHazeMovementComponent::Get(Owner);
		MoveData = MovementComponent.SetupMovementData(USkylineFlyingCarMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MovementComponent.HasMovedThisFrame())
			return false;

		if (Car.ActiveHighway == nullptr)
			return false;

		if (!Car.ActiveHighway.IsA(ASkylineFlyingCarHighwayRamp))
			return false;

		if (Car.bSplineRampJump)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSkylineFlyingCarGotySplineRampMovementCapabilityDeactivationParams& DeactivationParams) const
	{
		if (MovementComponent.HasMovedThisFrame())
			return true;

		if (Car.ActiveHighway == nullptr)
			return true;

		if (!Car.ActiveHighway.IsA(ASkylineFlyingCarHighwayRamp))
			return true;

		if (bReachedEndOfRampSpline)
		{
			DeactivationParams.bReachedEndOfSpline = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Car.bInSplineRamp = true;
		HighwayRamp = Cast<ASkylineFlyingCarHighwayRamp>(Car.ActiveHighway);
		bReachedEndOfRampSpline = false;
		bSteepClimbing = false;
		bBoosting = false;

		MoveSpeed = Math::Max(Car.ActorVelocity.Size(), 1.0);
		PreviousMeshRotation = Car.MeshRoot.WorldRotation;

		// Camera juice
		SpeedEffect::RequestSpeedEffect(Car.Pilot, 0.1, this, EInstigatePriority::Normal);

		AcceleratedInput.SnapTo(FVector(0, Car.YawInput, Car.PitchInput));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSkylineFlyingCarGotySplineRampMovementCapabilityDeactivationParams DeactivationParams)
	{
		// Trigger jump capability
		if (DeactivationParams.bReachedEndOfSpline)
			Car.bSplineRampJump = true;

		// Clean juice
		SpeedEffect::ClearSpeedEffect(Car.Pilot, this);
		Car.Pilot.StopCameraShakeByInstigator(this);

		// FF
		for (auto Player : Game::Players)
			Player.PlayForceFeedback(HighwayRamp.RampBoostEndFF, false, false, this);

		// VFX
		USkylineFlyingCarEventHandler::Trigger_OnRampBoostEnd(Car);

		Car.bInSplineRamp = false;
		HighwayRamp = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				AcceleratedInput.AccelerateTo(FVector(0, Car.YawInput, Car.PitchInput), 0.5, DeltaTime);

				FSkylineFlyingCarSplineParams SplineParams;
				Car.GetSplineDataAtPosition(Car.ActorLocation, SplineParams);
				FSplinePosition SplinePosition = SplineParams.SplinePosition;

				if (SplinePosition.WorldForwardVector.DotProduct(FVector::UpVector) >= 0.5)
					bSteepClimbing = true;

				float TargetMoveSpeed = Settings.SplineMoveSpeed * HighwayRamp.MovementSpeedScale;
				float InterpSpeed = MoveSpeed < TargetMoveSpeed ? Settings.SplineMoveSpeedAcceleration : Settings.SplineMoveSpeedDeceleration;
				MoveSpeed = Math::FInterpTo(MoveSpeed, TargetMoveSpeed, DeltaTime, InterpSpeed * Settings.RampSplineMoveSpeedAccelerationMultiplier);

				float RemainingDistance;
				FVector FirstPosition = SplinePosition.WorldLocation;
				SplinePosition.Move(MoveSpeed, RemainingDistance);
				FVector LastPosition = SplinePosition.WorldLocation;

				// Eman TODO: Move this before spline move and fix bullshite
				if (SplinePosition.IsAtEnd())
					bReachedEndOfRampSpline = true;

				FVector MoveDelta = (LastPosition - FirstPosition).ConstrainToDirection(SplinePosition.WorldForwardVector);
				FQuat Heading = Math::QInterpTo((MovementComponent.PreviousVelocity * DeltaTime).ToOrientationQuat(), MoveDelta.ToOrientationQuat(), DeltaTime, 20);
				MoveDelta = Heading.Vector() * MoveDelta.Size();
				MoveData.AddVelocity(MoveDelta);

				// Horizontal movement
				{
					float HorizontalSpeed = Math::FInterpTo(PreviousHorizontalSpeed, AcceleratedInput.Value.Y * Settings.YawRotationSpeed * Math::Pow(Settings.MaxSplineOffsetSteeringAngle, 2) * 0.1, DeltaTime, Settings.ReturnToIdleRotationSpeed * 0.5);
					PreviousHorizontalSpeed = HorizontalSpeed;
					FVector HorizontalMovement = SplinePosition.WorldRightVector * HorizontalSpeed;

					FSkylineFlyingCarSplineParams HorizontalMoveParams;
					FVector ConstrainedLocation = Car.ActorLocation + HorizontalMovement * DeltaTime;
					Car.GetSplineDataAtPosition(ConstrainedLocation, HorizontalMoveParams);

					FlyingCar::SoftConstrainLocationToHighwayBounds(HorizontalMoveParams, HorizontalMovement, 0.2, false);
					MoveData.AddVelocity(HorizontalMovement);
				}

				// Vertical offset
				{
					FVector CarToSpline = (SplinePosition.WorldLocation - Car.ActorLocation);
					FVector VerticalCarToSpline = CarToSpline.ConstrainToDirection(SplinePosition.WorldUpVector);
					FVector HorizontalCarToSpline = CarToSpline.ConstrainToPlane(SplinePosition.WorldUpVector);

					float CurrentOffset = VerticalCarToSpline.DotProduct(-SplinePosition.WorldUpVector);

					float TargetHeight = GetTargetHeight(SplinePosition, CurrentOffset, DeltaTime);
					float Offset = Math::FInterpTo(CurrentOffset, TargetHeight, DeltaTime, 100);
					FVector TargetLocation = SplinePosition.WorldLocation + SplinePosition.WorldUpVector * Offset - HorizontalCarToSpline;

					FVector VerticalMoveDelta = TargetLocation - Car.ActorLocation;
					MoveData.AddDelta(VerticalMoveDelta * DeltaTime);
				}

				// Rotation
				{
					MoveData.InterpRotationTo(SplinePosition.WorldRotation, 2.0, false);

					// Update crumbed rotation
					Car.CrumbedMeshRotation.Value = CalculateMeshRotation(DeltaTime).Rotator();
				}

				MoveData.BlockGroundTracingForThisFrame();
			}
			else
			{
				MoveData.ApplyCrumbSyncedAirMovement();
			}

			MovementComponent.ApplyMove(MoveData);

			Car.MeshRoot.WorldRotation = Car.CrumbedMeshRotation.Value;
			PreviousMeshRotation = Car.MeshRoot.WorldRotation;
		}

		if (!bBoosting && bSteepClimbing)
		{
			// Camera juice
			SpeedEffect::RequestSpeedEffect(Car.Pilot, 0.5, this, EInstigatePriority::Normal);
			if(HighwayRamp.CameraShakeClass.IsValid())
				Car.Pilot.PlayCameraShake(HighwayRamp.CameraShakeClass, this, 0.5);

			// VFX
			USkylineFlyingCarEventHandler::Trigger_OnRampBoostStart(Car);


			bBoosting = true;
		}

		// FF juicep
		TickForceFeedback();
	}
 
	FQuat CalculateMeshRotation(float DeltaTime)
	{
		FQuat Pitch = FQuat(Car.MeshRoot.RightVector, Math::DegreesToRadians(-Settings.PitchMeshRotation.UpdateAngle(Car.PitchInput, DeltaTime))); 
		FQuat Roll = FQuat(Car.MeshRoot.ForwardVector, Math::DegreesToRadians(-Settings.RollMeshRotation.UpdateAngle(Car.YawInput, DeltaTime)));
		FQuat Yaw = FQuat(Car.MeshRoot.UpVector, Math::DegreesToRadians(Settings.YawMeshRotation.UpdateAngle(Car.YawInput, DeltaTime)));

		FQuat MeshRotation = Pitch * Roll * Yaw * Car.ActorQuat;

		return MeshRotation;
	}

	void TickForceFeedback()
	{
		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::Abs(Math::PerlinNoise1D(Math::Max(0.1, Time::GameTimeSeconds * 150)));
		FF.RightMotor = Math::Abs(Math::PerlinNoise1D(Math::Max(0.1, Time::GameTimeSeconds * 200)));

		if (bBoosting)
		{
			float Value = Math::Abs(Math::PerlinNoise1D(Math::Max(0.2, Time::GameTimeSeconds * 300)));
			FF.LeftTrigger = Value;
			FF.RightTrigger = Value;
		}

		ForceFeedback::PlayWorldForceFeedbackForFrame(FF, Car.ActorLocation, 1000);
	}

	float GetTargetHeight(FSplinePosition SplinePosition, float CurrentOffset, float DeltaTime)
	{
		// It's all good if spline ain't climbing
		if (SplinePosition.WorldForwardVector.DotProduct(FVector::UpVector) < 0.5)
			return CurrentOffset;

		if (!bPullUpMode)
			return 0;

		AcceleratedHeightSpeed.AccelerateTo(500 * AcceleratedInput.Value.Z, 1.0, DeltaTime);

		float TargetHeight = Math::Min(CurrentOffset + AcceleratedHeightSpeed.Value, 0.0);
		return TargetHeight;
	}
}