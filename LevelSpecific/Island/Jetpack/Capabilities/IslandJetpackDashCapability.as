struct FIslandJetpackDashActivationParams
{
	bool bThrusterWasOn = false;
}

class UIslandJetpackDashCapability : UHazePlayerCapability
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
	default TickGroupSubPlacement = 4;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 5, 2);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AIslandJetpack Jetpack;

	UIslandJetpackComponent JetpackComp;

	UIslandSidescrollerComponent SidescrollerComp;

	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;

	UIslandJetpackSettings JetpackSettings;

	float StartHorizontalSpeed;
	FVector Direction;
	FHazeAcceleratedVector AcceleratedImpulses;

	AHazePlayerCharacter CameraShakePlayer;

	const float StartHorizontalSpeedInterpSpeed = 7.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JetpackComp = UIslandJetpackComponent::Get(Player);
		Jetpack = JetpackComp.Jetpack;

		SidescrollerComp = UIslandSidescrollerComponent::GetOrCreate(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();

		JetpackSettings = UIslandJetpackSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandJetpackDashActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(MoveComp.IsOnWalkableGround())
			return false;

		if(!JetpackComp.IsOn())
			return false;

		if(JetpackComp.HasEmptyCharge())
			return false;

		if(!WasActionStarted(ActionNames::MovementDash))
			return false;
		
		if(JetpackComp.bThrusterIsOn)
		{
			Params.bThrusterWasOn = true;
			return true;
		}
		if(MoveComp.IsInAir())
		{
			Params.bThrusterWasOn = false;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!JetpackComp.IsOn())
			return true;

		if(MoveComp.IsOnAnyGround())
			return true;

		if(!JetpackComp.bThrusterIsOn)
			return true;

		if(ActiveDuration > JetpackSettings.DashDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandJetpackDashActivationParams Params)
	{
		if(!Params.bThrusterWasOn)
			JetpackComp.bActivatedExternally = true;

		JetpackComp.ChangeChargeLevel(-JetpackSettings.DashActivationDepletion, true);
		StartHorizontalSpeed = Player.ActorHorizontalVelocity.Size();

		if(MoveComp.MovementInput.IsNearlyZero())
			Direction = Player.ActorForwardVector;
		else
			Direction = MoveComp.MovementInput;


		JetpackComp.AddHoldEffectInstigator(this);
		JetpackComp.bDashing = true;
		JetpackComp.TimeOfDash = Time::GetGameTimeSeconds();

		UIslandJetpackEventHandler::Trigger_JetpackDash(Jetpack);
		AcceleratedImpulses.SnapTo(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Turn the meter back to original color
		JetpackComp.ChangeChargeLevel(0.0, false);
		JetpackComp.RemoveHoldEffectInstigator(this);

		JetpackComp.bDashing = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector Input = MoveComp.GetMovementInput().GetSafeNormal();
				if(Input.IsNearlyZero())
					Input = Player.ActorForwardVector;

				if(MoveComp.HasImpulse())
				{
					FVector PendingImpulse = MoveComp.GetPendingImpulse();
					AcceleratedImpulses.SnapTo(AcceleratedImpulses.Value + PendingImpulse, AcceleratedImpulses.Velocity);
				}

				Movement.AddVelocity(AcceleratedImpulses.Value);

				AcceleratedImpulses.AccelerateTo(FVector::ZeroVector, 0.5, DeltaTime);			

				FVector HorizontalVelocity = Player.ActorHorizontalVelocity;
				FVector VerticalVelocity = Player.ActorVerticalVelocity;

				bool bIsGoingDownwards = MoveComp.VerticalSpeed < 0;

				float VerticalSpeedBoost = 0.0;

				if(bIsGoingDownwards)
					VerticalSpeedBoost = JetpackSettings.HoldVerticalBoostGoingDownMultiplier * JetpackSettings.HoldVerticalBoost;

				VerticalVelocity += MoveComp.WorldUp * VerticalSpeedBoost * DeltaTime;
				VerticalVelocity = Math::VInterpTo(VerticalVelocity, FVector::ZeroVector, DeltaTime, JetpackSettings.HoldVerticalDeceleration);

				float DashAlpha = ActiveDuration / JetpackSettings.DashDuration;
				float DashAdditionalSpeed = JetpackSettings.DashSpeedCurve.GetFloatValue(DashAlpha) * JetpackSettings.DashAdditionalSpeedMax;

				Direction = Math::VInterpTo(Direction, Input, DeltaTime, JetpackSettings.DashRedirectionSpeed);

				if(StartHorizontalSpeed < JetpackSettings.MinimumDashExitSpeed)
					StartHorizontalSpeed = Math::FInterpTo(StartHorizontalSpeed, JetpackSettings.MinimumDashExitSpeed, DeltaTime, StartHorizontalSpeedInterpSpeed);
				float DashSpeed = Math::Min(DashAdditionalSpeed + StartHorizontalSpeed, JetpackSettings.DashMaxSpeed);
				HorizontalVelocity = Direction * DashSpeed;

				Movement.AddVelocity(VerticalVelocity);
				Movement.AddVelocity(HorizontalVelocity);

				if(SidescrollerComp.IsInSidescrollerMode())
				{
					Movement.InterpRotationTo(Direction.ToOrientationQuat(), JetpackSettings.InterpRotationSpeed);
				}
				else
				{
					Movement.InterpRotationTo(Player.GetCameraDesiredRotation().Quaternion(), JetpackSettings.InterpRotationSpeed);
				}
				// Just so it colors it red, the charge is already paid at start
				JetpackComp.ChangeChargeLevel(0.0, true);

				TEMPORAL_LOG(Player, "Jetpack")
					.Value("Dash Additional Speed", DashAdditionalSpeed)
					.Value("Start Horizontal Speed", StartHorizontalSpeed)
					.Value("Dash Speed", DashSpeed)
				;
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Jetpack");
		}
	}
};