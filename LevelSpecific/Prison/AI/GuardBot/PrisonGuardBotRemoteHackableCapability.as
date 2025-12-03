class UPrisonGuardBotRemoteHackableCapability : URemoteHackableBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Movement;

	UHazeMovementComponent MoveComp;
	UBasicAIHealthComponent HealthComp;
	UBasicAIHealthBarComponent HealthBarComp;
	UGentlemanComponent GentlemanComp;
	UPrisonGuardBotZapperAutoAimTargetComponent AutoAimTargetComp;
	USweepingMovementData Movement;
	UPrisonGuardBotSettings Settings;
	FHazeAcceleratedRotator AccRotation;

	AAIPrisonGuardBot Bot;
	UPlayerAimingComponent AimComp;

	float IdealHeight;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		MoveComp = UHazeMovementComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HealthBarComp = UBasicAIHealthBarComponent::Get(Owner);
		PlayerMoveComp = UHazeMovementComponent::Get(Player);
		GentlemanComp = UGentlemanComponent::GetOrCreate(Player);
		AutoAimTargetComp = UPrisonGuardBotZapperAutoAimTargetComponent::Get(Owner);
		Movement = MoveComp.SetupSweepingMovementData();
		Settings = UPrisonGuardBotSettings::GetSettings(Owner);
		Bot = Cast<AAIPrisonGuardBot>(Owner);
		AimComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Bot.bIsControlledByPlayer = true;
		AccRotation.SnapTo(Owner.ActorRotation);

		// Hide health bar
		HealthBarComp.SetPlayerVisibility(EHazeSelectPlayer::None);

		Owner.BlockCapabilitiesExcluding(BasicAITags::Behaviour, n"HitReaction", this);
		Owner.BlockCapabilities(CapabilityTags::Movement, this);

		// No autoaim vs self!		
		AutoAimTargetComp.Disable(this);

		AAIPrisonGuardBotZapper Zapper = Cast<AAIPrisonGuardBotZapper>(Owner);
		if (Zapper != nullptr)
		{
			if (Zapper.bShowTutorial)
			{
				FTutorialPrompt ZapPrompt;
				ZapPrompt.Action = ActionNames::PrimaryLevelAbility;
				ZapPrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
				ZapPrompt.Text = Zapper.ZapTutorialText;
				ZapPrompt.MaximumDuration = 8.0;
				Player.ShowTutorialPrompt(ZapPrompt, this);
			}

			UPlayerAimingSettings::SetScreenSpaceAimOffset(Player, FVector2D(FVector2D::ZeroVector), this);
			AimComp.StartAiming(Owner, Zapper.AimSettings);
		}

		Player.HealPlayerHealth(1.0);

		IdealHeight = UHazeActorRespawnableComponent::Get(Owner).Spawner.ActorLocation.Z;

		UCameraSettings::GetSettings(Player).SensitivityFactor.Apply(1.25, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Bot.bIsControlledByPlayer = false;

		Timer::SetTimer(this, n"SetValidTargetDelayed", 0.5);

		Owner.UnblockCapabilities(BasicAITags::Behaviour, this);
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);

		AutoAimTargetComp.Enable(this);

		// Show health bar again (if appropriate)
		HealthBarComp.SetPlayerVisibility(EHazeSelectPlayer::Mio);

		Player.ClearGravityDirectionOverride(this);

		// Destroy drone when leaving
		HealthComp.TakeDamage(HealthComp.MaxHealth, EDamageType::Explosion, Player);

		Player.RemoveTutorialPromptByInstigator(this);

		UPlayerAimingSettings::ClearScreenSpaceAimOffset(Player, this);
		AimComp.StopAiming(Owner);

		UCameraSettings::GetSettings(Player).SensitivityFactor.Clear(this, 0.0);
	}

	UFUNCTION()
	private void SetValidTargetDelayed()
	{
		if (!IsActive())
			GentlemanComp.ClearInvalidTarget(this);		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;

		if(Player.HasControl())
		{
			FVector FwdAcc = Player.ViewRotation.ForwardVector * GetAttributeFloat(AttributeNames::MoveForward) * Settings.HackedMovementAccelerationForward;
			FwdAcc.Z = 0.0;
			FVector RightAcc = Player.ViewRotation.RightVector * GetAttributeFloat(AttributeNames::MoveRight) * Settings.HackedMovementAccelerationRight;
			RightAcc.Z = 0.0;

			FVector UpAcc = FVector::ZeroVector;
			if (Owner.ActorLocation.Z > IdealHeight + Settings.HackedMovementIdealHeightOffsetUp)
				UpAcc.Z -= Settings.HackedMovementAccelerationUp;
			else if (Owner.ActorLocation.Z < IdealHeight - Settings.HackedMovementIdealHeightOffsetDown)
				UpAcc.Z += Settings.HackedMovementAccelerationUp;
			else 
				UpAcc.Z += Math::Sin(ActiveDuration * 2.0) * 30.0;// Bob a bit	

			Movement.AddAcceleration(FwdAcc + RightAcc + UpAcc);
			Movement.AddAcceleration(-MoveComp.Velocity * Settings.HackedMovementFriction);

			AccRotation.Value = Owner.ActorRotation;  // In case something else has rotated us
			AccRotation.AccelerateTo(Player.ViewRotation, Settings.HackedMovementRotationDuration, DeltaTime);
			Movement.SetRotation(AccRotation.Value);

			Movement.AddVelocity(MoveComp.Velocity);
			MoveComp.ApplyMove(Movement);
		}
		else
		{
			Movement.ApplyCrumbSyncedAirMovement();
			MoveComp.ApplyMove(Movement);
		}
	}
}