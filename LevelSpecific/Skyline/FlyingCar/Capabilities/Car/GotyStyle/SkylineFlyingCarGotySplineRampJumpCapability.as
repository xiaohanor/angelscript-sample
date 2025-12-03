class USkylineFlyingCarGotySplineRampJumpCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	// Tick between ramp- and free movement
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 89;

	ASkylineFlyingCar Car;
	USkylineFlyingCarGotySettings Settings;

	default DebugCategory = n"FlyingCar";

	UHazeCameraComponent JumpFollowCamera;

	float CoolFlipFraction;

	// Increase pitch a bit
	const FRotator CameraRotationOffset = FRotator(20, 0, 0);

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Car = Cast<ASkylineFlyingCar>(Owner);
		Settings = USkylineFlyingCarGotySettings::GetSettings(Owner);

		JumpFollowCamera = UHazeCameraComponent::GetOrCreate(Car, n"RampJumpFollowCamera");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Car.bSplineRampJump)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Deactivate when reaching a highway
		if (Car.ActiveHighway != nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto HighwayRamp = Cast<ASkylineFlyingCarHighwayRamp>(Car.ActiveHighway);

		// Jump away
		FVector JumpImpulse = HighwayRamp.GetImpulseToReachJumpTarget(Car.ActorLocation);
		Car.SetActorVelocity(JumpImpulse);

		FHazeCameraImpulse CameraImpulse;
		CameraImpulse.WorldSpaceImpulse = JumpImpulse;
		Car.Pilot.ApplyCameraImpulse(CameraImpulse, this);

		// Pwn highway
		HighwayRamp.SetEnabled(false);
		Car.SetActiveHighway(nullptr);

		// Make gravity constant
		float GravityScale = Settings.FreeFlyPitchGravityMultiplier.Max * 0.95;
		USkylineFlyingCarGotySettings::SetFreeFlyPitchGravityMultiplier(Car, FHazeRange(GravityScale, GravityScale), this);

		// Fire hop event
		USkylineFlyingCarEventHandler::Trigger_OnSplineHopStart(Car);

		// Cool camera maybe?
		if (JumpFollowCamera != nullptr)
		{
			Car.Pilot.ActivateCamera(JumpFollowCamera, 2, this, EHazeCameraPriority::VeryHigh);
			Car.Gunner.ActivateCamera(JumpFollowCamera, 2, this, EHazeCameraPriority::VeryHigh);
		}

		CoolFlipFraction = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// This accelerators seem to be reset when clearing settings, so do this disgusting thing
		{
			auto AcceleratedPitch = Settings.PitchMeshRotation;
			auto AcceleratedRoll = Settings.RollMeshRotation;
			auto AcceleratedYaw = Settings.YawMeshRotation;

			USkylineFlyingCarGotySettings::ClearFreeFlyPitchGravityMultiplier(Car, this);

			Settings.YawMeshRotation = AcceleratedYaw;
			Settings.RollMeshRotation = AcceleratedRoll;
			Settings.PitchMeshRotation = AcceleratedPitch;
		}

		Car.bSplineRampJump = false;
		Car.bJustSplineHopped = true;
		Car.MeshRootRotationOffset = FQuat::Identity;

		// Cool camera maybe?
		if (JumpFollowCamera != nullptr)
		{
			Car.Pilot.DeactivateCamera(JumpFollowCamera, 2.0);
			Car.Gunner.DeactivateCamera(JumpFollowCamera, 2.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (JumpFollowCamera != nullptr)
		{
			JumpFollowCamera.SetWorldLocation(Car.ActorLocation + FVector::UpVector * 400 - Car.ActorForwardVector * 300);

			FRotator CameraRotation = (Car.ActorLocation - Car.Pilot.ViewLocation).Rotation() + CameraRotationOffset;
			CameraRotation = Math::RInterpTo(JumpFollowCamera.WorldRotation, CameraRotation, DeltaTime, 5);
			JumpFollowCamera.SetWorldRotation(CameraRotation);
		}

		float TargetAlpha = Math::Pow(Math::Saturate(ActiveDuration / 3), 2);
		CoolFlipFraction = Math::FInterpTo(CoolFlipFraction, TargetAlpha, DeltaTime, 5);
		float Pitch = Math::Lerp (2 * PI, 0, CoolFlipFraction);

		FQuat PitchRotation = FQuat(Car.ActorRightVector, Pitch);
		Car.MeshRootRotationOffset = PitchRotation;
	}
}