struct FFlyingCarOfficeCrashCapabilityActivationParams
{
	FFlyingCarOfficeCrashParams CrashParams;
	float RotationDirection;
}

class UFlyingCarOfficeCrashCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	// Activate before ground movement
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 88;

	ASkylineFlyingCar Car;
	UFlyingCarOfficeCrashComponent OfficeCrashComponent;

	UHazeMovementComponent MovementComponent;
	USkylineFlyingCarMovementData MoveData;

	USkylineFlyingCarGotySettings Settings;

	float RotationDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Car = Cast<ASkylineFlyingCar>(Owner);
		OfficeCrashComponent = Car.OfficeCrashComponent;

		MovementComponent = Car.MovementComponent;
		MoveData = MovementComponent.SetupMovementData(USkylineFlyingCarMovementData);

		Settings = USkylineFlyingCarGotySettings::GetSettings(Car);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FFlyingCarOfficeCrashCapabilityActivationParams& ActivationParams) const
	{
		if (!OfficeCrashComponent.bCrashing)
			return false;

		ActivationParams.CrashParams = OfficeCrashComponent.ActiveCrashParams;
		ActivationParams.RotationDirection = Car.YawInput < 0 ? -1 : 1;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > OfficeCrashComponent.ActiveCrashParams.Time * 0.5)
		{
			if (MovementComponent.HasMovedThisFrame())
				return true;

			if (FlyingCar::IsOnSlidingGround(MovementComponent))
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FFlyingCarOfficeCrashCapabilityActivationParams& ActivationParams)
	{
		OfficeCrashComponent.ActiveCrashParams = ActivationParams.CrashParams;
		RotationDirection = ActivationParams.RotationDirection;

		UMovementGravitySettings::SetGravityAmount(Car, Settings.GravityAmount, this);

		Car.SetActorVelocity(OfficeCrashComponent.ActiveCrashParams.Velocity);

		// Camera juice
		Car.Pilot.PlayCameraShake(OfficeCrashComponent.ActiveCrashParams.OfficeCrashTrigger.CrashCameraShakeClass, this);
		SpeedEffect::RequestSpeedEffect(Car.Pilot, 0.5, this, EInstigatePriority::Normal, 0.6);

		// FF juice
		Car.Pilot.PlayForceFeedback(OfficeCrashComponent.ActiveCrashParams.OfficeCrashTrigger.CrashForceFeedbackAsset, false, false, this);
		Car.Gunner.PlayForceFeedback(OfficeCrashComponent.ActiveCrashParams.OfficeCrashTrigger.CrashForceFeedbackAsset, false, false, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMovementGravitySettings::ClearGravityAmount(Car, this);

		OfficeCrashComponent.ActiveCrashParams = FFlyingCarOfficeCrashParams();
		OfficeCrashComponent.bCrashing = false;

		SpeedEffect::ClearSpeedEffect(Car.Pilot, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				MoveData.AddOwnerVelocity();
				MoveData.AddGravityAcceleration();

				MoveData.SetRotation(MovementComponent.Velocity.Rotation());

				// Stepdowns can bring car down before jump, ignore for first half of air time
				if (ActiveDuration < OfficeCrashComponent.ActiveCrashParams.Time * 0.5)
					MoveData.BlockGroundTracingForThisFrame();
			}
			else
			{
				MoveData.ApplyCrumbSyncedAirMovement();
			}

			MovementComponent.ApplyMove(MoveData);

			// Mesh rotation
			float Multiplier = Math::Pow(Math::Saturate(ActiveDuration / 0.3), 1.374);

			FQuat Pitch = FQuat(Car.MeshRoot.RightVector, 0.3 * DeltaTime);
			FQuat Yaw = FQuat(Car.MeshRoot.UpVector, 0.1 * DeltaTime * RotationDirection);
			FQuat Roll = FQuat(Car.MeshRoot.ForwardVector, 0.2 * DeltaTime * RotationDirection);

			FQuat TargetRotation = Pitch * Yaw * Roll * Car.Mesh.ComponentQuat * Multiplier;
			Car.MeshRoot.SetWorldRotation(TargetRotation);
		}
	}
}