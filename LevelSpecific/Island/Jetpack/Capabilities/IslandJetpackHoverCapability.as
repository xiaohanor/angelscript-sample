class UIslandJetpackHoverCapability : UHazePlayerCapability
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

	default BlockExclusionTags.Add(n"ExcludeAirJumpAndDash");

	default DebugCategory = IslandJetpack::Jetpack;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 50;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AIslandJetpack Jetpack;

	UIslandJetpackComponent JetpackComp;
	UIslandSidescrollerComponent SidescrollerComp;

	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;

	UIslandJetpackSettings JetpackSettings;

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
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(MoveComp.IsOnWalkableGround())
			return false;

		if(!JetpackComp.IsOn())
			return false;

		if(JetpackComp.HasEmptyCharge())
			return false;

		if(JetpackComp.bHasInitialBoost)
			return false;

		if(!JetpackComp.bThrusterIsOn)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!JetpackComp.IsOn())
			return true;

		if(WasActionStarted(ActionNames::Cancel))
			return true;

		if(JetpackComp.HasEmptyCharge())
			return true;

		if(MoveComp.IsOnAnyGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		JetpackComp.AddHoldEffectInstigator(this);
		//UIslandJetpackEventHandler::Trigger_JetpackActivated(Jetpack);
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		JetpackComp.RemoveHoldEffectInstigator(this);
		//UIslandJetpackEventHandler::Trigger_ThrusterCancel(Jetpack);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector Input = MoveComp.GetMovementInput();

				Movement.AddPendingImpulses();

				FVector HorizontalVelocity = Player.ActorHorizontalVelocity;
				FVector VerticalVelocity = Player.ActorVerticalVelocity;

				bool bIsGoingDownwards = MoveComp.VerticalSpeed < 0;

				float VerticalSpeedBoost = 0.0;

				if(bIsGoingDownwards)
					VerticalSpeedBoost = JetpackSettings.HoldVerticalBoostGoingDownMultiplier * JetpackSettings.HoldVerticalBoost;

				VerticalVelocity += MoveComp.WorldUp * VerticalSpeedBoost * DeltaTime;
				VerticalVelocity = Math::VInterpTo(VerticalVelocity, FVector::ZeroVector, DeltaTime, JetpackSettings.HoldVerticalDeceleration);

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
			JetpackComp.ChangeChargeLevel(-ChargeDepletionSpeed * DeltaTime, false);

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Jetpack");
		}
	}
};