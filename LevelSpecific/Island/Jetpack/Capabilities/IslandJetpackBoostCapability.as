struct FIslandJetpackBoostActivationParams
{
	bool bIsInitialBoost = false;
	bool bIsPhaseWallBoost = false;
}

class UIslandJetpackBoostCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::Jump);
	default CapabilityTags.Add(PlayerMovementTags::AirJump);
	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::WallRun);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::Vault);
	default CapabilityTags.Add(BlockedWhileIn::LedgeMantle);
	default CapabilityTags.Add(IslandJetpack::Jetpack);
	default CapabilityTags.Add(IslandJetpack::BlockedWhileInPhasableMovement);

	default BlockExclusionTags.Add(n"ExcludeAirJumpAndDash");

	default DebugCategory = IslandJetpack::Jetpack;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 40;
	default TickGroupSubPlacement = 3;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 5, 1);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AIslandJetpack Jetpack;
	AHazePlayerCharacter CameraShakePlayer;

	UIslandJetpackComponent JetpackComp;
	UCameraUserComponent CameraUserComp;
	UIslandSidescrollerComponent SidescrollerComp;

	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;

	UIslandJetpackSettings JetpackSettings;

	bool bIsInitialBoosting = false;
	bool bIsPhaseWallBoost = false;
	float TimeOfStartPhaseWallBoost;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JetpackComp = UIslandJetpackComponent::Get(Player);
		Jetpack = JetpackComp.Jetpack;

		SidescrollerComp = UIslandSidescrollerComponent::GetOrCreate(Player);

		CameraUserComp = UCameraUserComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();

		JetpackSettings = UIslandJetpackSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandJetpackBoostActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(MoveComp.IsOnWalkableGround())
			return false;

		if(!JetpackComp.IsOn())
			return false;

		if(JetpackComp.HasEmptyCharge())
			return false;

		if(!JetpackComp.bThrusterIsOn)
			return false;

		if(JetpackComp.bQueuedPhaseWallBoost)
		{
			Params.bIsPhaseWallBoost = true;
			return true;
		}

		if(JetpackComp.bHasInitialBoost)
		{
			Params.bIsInitialBoost = true;
			return true;
		}
		
		if(WasActionStarted(ActionNames::MovementJump))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!JetpackComp.IsOn())
			return true;

		if(JetpackComp.HasEmptyCharge())
			return true;

		if(MoveComp.IsOnAnyGround())
			return true;

		if(!JetpackComp.bThrusterIsOn)
			return true;
		
		if(!IsActioning(ActionNames::MovementJump)
		&& !bIsInitialBoosting && !bIsPhaseWallBoost)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandJetpackBoostActivationParams Params)
	{
		if(Params.bIsPhaseWallBoost)
			TogglePhaseWallBoost(true);
		else if(Params.bIsInitialBoost)
			StartInitialBoost();
		else
			ToggleHoldBoost(true);

		Player.BlockCapabilities(PlayerMovementTags::AirDash, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		bIsPhaseWallBoost = false;
		bIsInitialBoosting = false;
		Player.StopCameraShakeByInstigator(this, false);

		StopInitialBoost();
		ToggleHoldBoost(false);
		
		Player.StopForceFeedback(this);

		Player.UnblockCapabilities(PlayerMovementTags::AirDash, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl() && JetpackComp.bQueuedPhaseWallBoost)
			CrumbTogglePhaseWallBoost(true);

		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector Input = MoveComp.GetMovementInput();

				Movement.AddPendingImpulses();

				FVector HorizontalVelocity = Player.ActorHorizontalVelocity;
				FVector VerticalVelocity = Player.ActorVerticalVelocity;

				bool bIsGoingDownwards = MoveComp.VerticalSpeed < 0;

				if(bIsPhaseWallBoost)
				{
					float Alpha = Time::GetGameTimeSince(TimeOfStartPhaseWallBoost) / JetpackSettings.PhaseWallBoostDuration;
					float VerticalSpeedBoost = JetpackSettings.PhaseWallBoostSpeedCurve.GetFloatValue(Alpha) * JetpackSettings.PhaseWallBoostSpeedMax;

					// Is going downwards
					if(bIsGoingDownwards)
						VerticalSpeedBoost *= JetpackSettings.PhaseWallBoostGoingDownMultiplier;
					
					VerticalVelocity += MoveComp.WorldUp * VerticalSpeedBoost * DeltaTime;
					Movement.AddGravityAcceleration();
					
					if(Time::GetGameTimeSince(TimeOfStartPhaseWallBoost) >= JetpackSettings.PhaseWallBoostDuration)
						TogglePhaseWallBoost(false);

					// If we were in initial boost and entered phase wall we want to exit initial boost so we just normal boost when exiting phase wall boost
					if(bIsInitialBoosting && ActiveDuration >= JetpackSettings.InitialBoostDuration)
						StopInitialBoost();
				}
				else if(bIsInitialBoosting)
				{
					float Alpha = ActiveDuration/JetpackSettings.InitialBoostDuration;
					float VerticalSpeedBoost = JetpackSettings.InitialBoostSpeedCurve.GetFloatValue(Alpha) * JetpackSettings.InitialBoostSpeedMax;

					// Is going downwards
					if(bIsGoingDownwards)
						VerticalSpeedBoost *= JetpackSettings.InitialBoostGoingDownMultiplier;
					
					VerticalVelocity += MoveComp.WorldUp * VerticalSpeedBoost * DeltaTime;
					Movement.AddGravityAcceleration();
					
					if(ActiveDuration >= JetpackSettings.InitialBoostDuration)
						StopInitialBoost();
				}
				else
				{
					float VerticalSpeedBoost = JetpackSettings.HoldBoost;
					VerticalVelocity = Math::VInterpTo(VerticalVelocity, FVector::ZeroVector, DeltaTime, JetpackSettings.HoldDeceleration);

					// Is going downwards
					if(bIsGoingDownwards)
						VerticalSpeedBoost *= JetpackSettings.InitialBoostGoingDownMultiplier;
					
					VerticalVelocity += MoveComp.WorldUp * VerticalSpeedBoost * DeltaTime;
					Movement.AddGravityAcceleration();

					ApplyBoostHaptic();
				}

				float HorizontalAcceleration = JetpackSettings.HorizontalVelocityAcceleration;

				// To make it turn around faster
				FVector HorizontalVelocityDir = -Player.ActorHorizontalVelocity.GetSafeNormal();
				float InputDotVelocityDir = Math::Max(Input.DotProduct(HorizontalVelocityDir), 0);
				HorizontalAcceleration += HorizontalAcceleration * InputDotVelocityDir * JetpackSettings.HorizontalVelocityNotGoingTowardsVelocityMultiplier;

				HorizontalVelocity += Input * HorizontalAcceleration  * DeltaTime;
				HorizontalVelocity = Math::VInterpTo(HorizontalVelocity, FVector::ZeroVector, DeltaTime, JetpackSettings.HorizontalVelocityDeceleration);

				Movement.AddVelocity(VerticalVelocity);
				Movement.AddVelocity(HorizontalVelocity);

				if(SidescrollerComp.IsInSidescrollerMode())
				{
					Movement.InterpRotationToTargetFacingRotation(-1);
				}
				else
				{
					Movement.InterpRotationTo(Player.GetCameraDesiredRotation().Quaternion(), JetpackSettings.InterpRotationSpeed);
				}
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			float ChargeDepletionSpeed = JetpackSettings.ChargeDepletionSpeed;
			if (!bIsPhaseWallBoost && !bIsInitialBoosting)
					ChargeDepletionSpeed = JetpackSettings.BoostChargeDepletionSpeed;
			JetpackComp.ChangeChargeLevel(-ChargeDepletionSpeed * DeltaTime, true);

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Jetpack");
		}
	}

	private void StartInitialBoost()
	{
		ToggleCameraShake(true);
		JetpackComp.bHasInitialBoost = false;
		bIsInitialBoosting = true;
		Jetpack.InitialJetEffect.Activate();
		Player.ApplyCameraImpulse(JetpackSettings.InitialBoostCameraImpulse, this);
		Player.PlayForceFeedback(JetpackSettings.InitialBoostRumble, false, false, this, 1.0);

		UIslandJetpackEventHandler::Trigger_ThrusterBoostFirstActivation(Jetpack);
	}

	private void StopInitialBoost()
	{
		bIsInitialBoosting = false;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbTogglePhaseWallBoost(bool bToggleOn)
	{
		TogglePhaseWallBoost(bToggleOn);
	}

	private void TogglePhaseWallBoost(bool bToggleOn)
	{
		JetpackComp.bQueuedPhaseWallBoost = false;

		if(bToggleOn)
		{
			Jetpack.InitialJetEffect.Activate();
			Player.PlayForceFeedback(JetpackSettings.InitialBoostRumble, true, false, this, 1.0);

			UIslandJetpackEventHandler::Trigger_ThrusterBoostStart(Jetpack);
			if(Player.ActorVerticalVelocity.Z < 0.0)
				Player.SetActorVerticalVelocity(FVector::ZeroVector);
			else if(JetpackSettings.ClampToMaxSizeVerticalVelocityWhenEnteringPhaseWall >= 0.0)
				Player.SetActorVerticalVelocity(Player.ActorVerticalVelocity.GetClampedToMaxSize(JetpackSettings.ClampToMaxSizeVerticalVelocityWhenEnteringPhaseWall));
		}
		else
		{
			Jetpack.InitialJetEffect.Deactivate();
			Player.StopForceFeedback(this);

			UIslandJetpackEventHandler::Trigger_ThrusterBoostStop(Jetpack);
		}
		ToggleCameraShake(bToggleOn);
		bIsPhaseWallBoost = bToggleOn;
		if(bIsPhaseWallBoost)
			TimeOfStartPhaseWallBoost = Time::GetGameTimeSeconds();
	}

	private void ToggleHoldBoost(bool bToggleOn)
	{
		if(bToggleOn)
		{
			Jetpack.InitialJetEffect.Activate();
			Player.PlayForceFeedback(JetpackSettings.InitialBoostRumble, true, false, this, 1.0);

			UIslandJetpackEventHandler::Trigger_ThrusterBoostStart(Jetpack);
		}
		else
		{
			Jetpack.InitialJetEffect.Deactivate();
			Player.StopForceFeedback(this);

			UIslandJetpackEventHandler::Trigger_ThrusterBoostStop(Jetpack);
		}
		ToggleCameraShake(bToggleOn);
	}

	private void ToggleCameraShake(bool bToggleOn)
	{
		if(bToggleOn)
		{
			if(SceneView::IsFullScreen())
				CameraShakePlayer = SceneView::FullScreenPlayer;
			else
				CameraShakePlayer = Player;

			CameraShakePlayer.PlayCameraShake(JetpackSettings.JetpackActivationShake, this);
		}
		else
			CameraShakePlayer.StopCameraShakeByInstigator(this);
	}

	private void ApplyBoostHaptic()
	{
		FHazeFrameForceFeedback ForceFeedBack;

		float BaseValue = 0.005;
		float NoiseBased = 0.010 * ((Math::PerlinNoise1D(Time::GameTimeSeconds * 3.5) + 1.0) * 0.5);
		
		float MotorStrength = (BaseValue + NoiseBased) * (JetpackSettings.HoldForceFeedbackMultiplier);

		ForceFeedBack.RightMotor = MotorStrength;
		Player.SetFrameForceFeedback(ForceFeedBack);
	}
};