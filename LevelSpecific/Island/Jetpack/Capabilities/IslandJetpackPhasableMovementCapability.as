class UIslandJetpackPhasableMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 30;
	default TickGroupSubPlacement = 3;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 4, 1);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = IslandJetpack::Jetpack;

	UIslandJetpackComponent JetpackComp;
	AIslandJetpack Jetpack;
	UIslandJetpackSettings JetpackSettings;
	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;
	UIslandJetpackPhasableComponent PhasableComp;

	FHazeAcceleratedFloat AccForwardSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JetpackComp = UIslandJetpackComponent::Get(Owner);
		Jetpack = JetpackComp.Jetpack;

		JetpackSettings = UIslandJetpackSettings::GetSettings(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();

		PhasableComp = UIslandJetpackPhasableComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		// float TimeWhenUsedPhasableWall = JetpackComp.TimeWhenUsedPhasableWall;
		// if (TimeWhenUsedPhasableWall < 0 || Time::GetGameTimeSince(TimeWhenUsedPhasableWall) > JetpackSettings.PhasableMovementMinDuration)
		// 	return false;
		if (PhasableComp.PhasablePlatformSpline == nullptr)
			return false;

		auto SplinePos = PhasableComp.PhasablePlatformSpline.Spline.GetClosestSplinePositionToWorldLocation(Player.ActorCenterLocation);

		float Dot = Player.ActorVelocity.GetSafeNormal().DotProduct(SplinePos.WorldForwardVector);
		if (Dot < 0.4)
			return false;

		if (PhasableComp.bQueuedPhasableSlowdown)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (PhasableComp.PhasablePlatformSpline == nullptr)
			return true;
		
		if (PhasableComp.bQueuedPhasableSlowdown)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		JetpackComp.AddHoldEffectInstigator(this);

		Player.BlockCapabilities(CameraTags::CameraControl, this);
		Player.BlockCapabilities(IslandJetpack::BlockedWhileInPhasableMovement, this);
		Player.BlockCapabilities(CapabilityTags::Input, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);

		JetpackComp.bDashing = true;

		if(HasControl())
		{
			auto SplinePos = PhasableComp.PhasablePlatformSpline.Spline.GetClosestSplinePositionToWorldLocation(Player.ActorCenterLocation);
			AccForwardSpeed.SnapTo(Player.ActorVelocity.DotProduct(SplinePos.WorldForwardVector));
		}

		UIslandJetpackEventHandler::Trigger_ThrusterBoostFirstActivation(Jetpack);
		Jetpack.InitialJetEffect.Activate();
		Player.PlayCameraShake(JetpackSettings.PhasableMovementCameraShake, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		JetpackComp.RemoveHoldEffectInstigator(this);
		JetpackComp.bDashing = false;
		Player.UnblockCapabilities(CameraTags::CameraControl, this);
		Player.UnblockCapabilities(IslandJetpack::BlockedWhileInPhasableMovement, this);
		Player.UnblockCapabilities(CapabilityTags::Input, this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		UIslandJetpackEventHandler::Trigger_ThrusterBoostStop(Jetpack);
		Jetpack.InitialJetEffect.Deactivate();
		if (PhasableComp.PhasablePlatformSpline != nullptr)
			Player.SetActorVelocity(Player.ActorForwardVector * PhasableComp.PhasablePlatformSpline.ExitSpeed);
		
		PhasableComp.PhasablePlatformSpline = nullptr;
		Player.StopCameraShakeByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				PhasableComp.AccFOV.AccelerateTo(JetpackSettings.PhasableMovementCameraMaxAdditiveFOV, JetpackSettings.PhasableMovementCameraFOVAccDuration, DeltaTime);
				UCameraSettings::GetSettings(Player).FOV.ApplyAsAdditive(PhasableComp.AccFOV.Value, n"PhasableMovement");
				auto SplinePos = PhasableComp.PhasablePlatformSpline.Spline.GetClosestSplinePositionToWorldLocation(Player.ActorCenterLocation);
				if (!SplinePos.Move(100))
					PhasableComp.bQueuedPhasableSlowdown = true;

				AccForwardSpeed.AccelerateTo(PhasableComp.PhasablePlatformSpline.MaxPhasableTraversalSpeed, JetpackSettings.PhasableMovementAccelerationDuration, DeltaTime);
				FRotator CurrentRotation = Player.GetViewRotation();
				float Alpha = Math::Saturate(ActiveDuration / 1.0);
				CurrentRotation = FQuat::Slerp(CurrentRotation.Quaternion(), SplinePos.WorldRotation, Alpha).Rotator();
				SplinePos.MatchFacingTo(Player.ActorVelocity.ToOrientationRotator());
				Player.SetCameraDesiredRotation(CurrentRotation, this);
				FVector ForwardDelta = SplinePos.WorldForwardVector * AccForwardSpeed.Value * DeltaTime;
				FVector YZPlaneDelta = (SplinePos.WorldLocation - Player.ActorLocation.PointPlaneProject(SplinePos.WorldLocation, SplinePos.WorldForwardVector)) * Alpha * DeltaTime;
				Movement.AddDelta(ForwardDelta);
				Movement.AddDelta(YZPlaneDelta);
				Movement.SetRotation((ForwardDelta+YZPlaneDelta).ToOrientationRotator());
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Jetpack");
		}
	}
}