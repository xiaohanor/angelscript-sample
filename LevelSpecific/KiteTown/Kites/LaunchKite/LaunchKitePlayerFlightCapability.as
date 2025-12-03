class ULaunchKitePlayerFlightCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(KiteTags::LaunchKite);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 30;

	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;

	ULaunchKitePlayerComponent LaunchKiteComp;

	float CurrentPitch = 0.0;
	float CurrentRoll = 0.0;

	FHazeAcceleratedFloat AccForwardSpeed;
	FHazeAcceleratedFloat AccSideSpeed;
	FHazeAcceleratedFloat AccVerticalSpeed;

	float MoveInputMultiplier = 0.0;
	FHazeAcceleratedVector2D AccMoveInput;

	float FlightVelocity = 2400.0;

	ALaunchKite Kite;

	FVector OriginalDirection = FVector::ZeroVector;

	float PlayerPitch = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();

		LaunchKiteComp = ULaunchKitePlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!LaunchKiteComp.bLaunched)
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (MoveComp.IsOnAnyGround())
			return true;

		if (MoveComp.HasAnyValidBlockingImpacts())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Kite = Cast<ALaunchKite>(LaunchKiteComp.LaunchKitePointComp.Owner);
		FlightVelocity = Kite.LaunchPointComp.FlightVelocity;

		OriginalDirection = Player.ActorForwardVector;

		AccForwardSpeed.SnapTo(FlightVelocity);
		AccSideSpeed.SnapTo(0.0);
		MoveInputMultiplier = 0.0;

		PlayerPitch = 0.0;

		Player.BlockCapabilities(PlayerMovementTags::AirDash, this);
		Player.BlockCapabilities(PlayerMovementTags::AirJump, this);
		Player.BlockCapabilities(CameraTags::CameraControl, this);

		Player.ResetAirJumpUsage();
		Player.ResetAirDashUsage();

		Player.ApplyCameraSettings(LaunchKiteComp.FlightCamSettings, 1.0, this, EHazeCameraPriority::High);
		Player.PlayCameraShake(LaunchKiteComp.FlightCamShake, this, 0.6);

		Player.PlayBlendSpace(LaunchKiteComp.FlyBS);

		ULaunchKitePlayerEffectEventHandler::Trigger_StartFlight(Player);
		UKiteTownVOEffectEventHandler::Trigger_LaunchStartFlight(Game::Mio, KiteTown::GetVOEffectEventParams(Player));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(PlayerMovementTags::AirDash, this);
		Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);
		Player.UnblockCapabilities(CameraTags::CameraControl, this);

		Player.ClearCameraSettingsByInstigator(this);
		Player.StopCameraShakeByInstigator(this);

		SpeedEffect::ClearSpeedEffect(Player, this);

		Player.MeshOffsetComponent.ResetOffsetWithLerp(this, 0.2);
		Player.Mesh.SetRelativeRotation(FRotator::ZeroRotator);

		LaunchKiteComp.LaunchKitePointComp = nullptr;
		LaunchKiteComp.bLaunched = false;

		if (!Player.IsAnyCapabilityActive(n"KiteFlight"))
			Player.StopBlendSpace();

		ULaunchKitePlayerEffectEventHandler::Trigger_StopFlight(Player);
		UKiteTownVOEffectEventHandler::Trigger_LaunchStopFlight(Game::Mio, KiteTown::GetVOEffectEventParams(Player));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector VelocityDir = OriginalDirection;
		VelocityDir.Z = Player.ActorVelocity.GetSafeNormal().Z;
		VelocityDir = VelocityDir.GetSafeNormal();

		FRotator CamRot = FRotator::MakeFromX(VelocityDir);
		float CameraPitch = Math::Clamp(CamRot.Pitch + Kite.LaunchPointComp.FlightCameraPitchOffset, -90.0, Kite.Pitch);
		FRotator CameraRot = Math::RInterpShortestPathTo(Player.ViewRotation, FRotator(CameraPitch, Player.ViewRotation.Yaw, 0.0), DeltaTime, 1.0);
		Player.SetCameraDesiredRotation(CameraRot, this);

		FRotator Rot = VelocityDir.Rotation();

		//So the LaunchKite capability has time to reset its own lerp
		if (ActiveDuration >= 0.2)
		{
			float TargetPitch = Rot.Pitch;
			PlayerPitch = Math::FInterpTo(PlayerPitch, TargetPitch, DeltaTime, 10.0);
			Player.MeshOffsetComponent.SnapToRotation(this, FQuat(FRotator(PlayerPitch, Player.ActorRotation.Yaw, 0.0)));
		}

		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

				FVector MoveDirection;
				MoveDirection += Player.ActorForwardVector * FlightVelocity;

				AccSideSpeed.AccelerateTo(MoveInput.Y * KiteFlight::StrafeSpeed, 0.75, DeltaTime);
				MoveDirection += Player.ActorRightVector * AccSideSpeed.Value;

				FVector MoveDelta = MoveDirection * DeltaTime;
				MoveDelta.Z = 0.0;
				Movement.AddDelta(MoveDelta);
				Movement.SetRotation(OriginalDirection.Rotation());

				CurrentRoll = Math::FInterpTo(CurrentRoll, MoveInput.Y, DeltaTime, 5.0);

				Player.SetBlendSpaceValues(CurrentRoll, 0.0);

				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Movement");
		}

		SpeedEffect::RequestSpeedEffect(Player, 0.5, this, EInstigatePriority::High);
	}
}