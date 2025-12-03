class USolarFlareTriggerShieldPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"TriggerShield");

	default TickGroup = EHazeTickGroup::BeforeMovement;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USolarFlareTriggerShieldComponent UserComp;
	USolarFlarePlayerComponent PlayerComp;
	USolarFlarePlayerComponent OtherPlayerComp;
	UPlayerMovementComponent MoveComp;

	ASolarFlareTriggerShield Shield;
	ASolarFlareSun Sun;

	// float UsageAmount = 1.65;
	float UsageAmount = 0.5;

	bool bWaveHit;
	bool bStartWaveReaction;
	bool bWaveHitCompleted;
	float ReactionDuration = 0.3;
	float ReactionTime;

	// USteppingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USolarFlareTriggerShieldComponent::Get(Player);
		PlayerComp = USolarFlarePlayerComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		// Movement = MoveComp.SetupSteppingMovementData();

		PlayerComp.OnSolarFlarePlayerRecievedHit.AddUFunction(this, n"OnSolarFlarePlayerRecievedHit");

		Shield = UserComp.SpawnShield(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (Sun == nullptr)
			Sun = TListedActors<ASolarFlareSun>().GetSingle();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// if (MoveComp.HasMovedThisFrame())
		// 	return false;

		if (MoveComp.IsInAir())
			return false;

		if (!UserComp.bHasTriggerShield)
			return false;

		if (UserComp.bEnergyWasDepleted)
			return false;

		if (UserComp.GetShieldEnergy() <= 0.0)
			return false;
		
		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bWaveHit)
		{
			if (bWaveHitCompleted)
				return true;
			
			return false;
		}

		if (!UserComp.bHasTriggerShield)
			return true;
		
		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return true;

		// if (UserComp.GetShieldEnergy() <= 0.0)
		// 	return true;
		
		if (UserComp.bEnergyWasDepleted)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (OtherPlayerComp == nullptr)
			OtherPlayerComp = USolarFlarePlayerComponent::Get(Player.OtherPlayer);
		
		UserComp.PlayTriggerFeedback(Player);
		bWaveHit = false;
		bWaveHitCompleted = false;
		bStartWaveReaction = false;

		PlayerComp.SetTriggerShieldActive(true);
		PlayerComp.AlterTriggerShieldProtected(true, Player);
		
		Shield.TurnOn();
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);

		Shield.ActorLocation = Player.ActorLocation;

		FSolarFlareTriggerShieldEffectHandlerParams Params;
		Params.Player = Player;
		Params.ShieldLocation = Shield.ActorLocation;
		USolarFlareTriggerShieldEffectHandler::Trigger_TurnedOn(Shield, Params);

		UserComp.RemovePrompt(Player);
		UserComp.TotalActivations++;

		FHazeSlotAnimSettings Settings;
		Settings.BlendTime = 0.3;
		Settings.BlendOutTime = 0.3;
		Settings.bLoop = true;
		Player.PlaySlotAnimation(UserComp.AnimBlock, Settings);

		Player.ApplyCameraSettings(UserComp.CameraSettings, 0.75, this);
		UserComp.Contraption.ShowEmissive(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UserComp.Contraption.ShowEmissive(false);

		if (!bWaveHitCompleted)
		{
			FSolarFlareTriggerShieldEffectHandlerParams Params;
			Params.Player = Player;
			Params.ShieldLocation = Shield.ActorLocation;
			USolarFlareTriggerShieldEffectHandler::Trigger_TurnedOff(Shield, Params);
		}

		Shield.TurnOff();

		PlayerComp.SetTriggerShieldActive(false);

		PlayerComp.AlterTriggerShieldProtected(false, Player);
		OtherPlayerComp.AlterTriggerShieldProtected(false, Player);

		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		
		UserComp.AddPrompt(Player);

		Player.StopAllSlotAnimations(0.3);
		Player.ClearCameraSettingsByInstigator(this, 0.75);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bWaveHit && !bStartWaveReaction)
		{
			ReactionTime = Time::GameTimeSeconds + ReactionDuration;
			bStartWaveReaction = true;

			UserComp.SetShieldEnergy(0.0);
			UserComp.SetDepleted();
			PlayerComp.SetInvincibleForDuration(0.5);
			
			if (OtherPlayerComp.bTriggerShieldProtecting[Player])
				OtherPlayerComp.SetInvincibleForDuration(0.5);
			
			Shield.TurnOff();
			FSolarFlareTriggerShieldEffectHandlerParams Params;
			Params.Player = Player;
			Params.ShieldLocation = Shield.ActorLocation;
			USolarFlareTriggerShieldEffectHandler::Trigger_Impact(Shield, Params);

			//Play reaction animation
		}

		if (bStartWaveReaction)
		{
			if (Time::GameTimeSeconds > ReactionTime)
				bWaveHitCompleted = true;

			return;
		}


		// Player.ActorRotation = Math::RInterpConstantTo(Player.ActorRotation, Shield.ActorForwardVector.Rotation(), DeltaTime, 180.0);
		Player.SetMovementFacingDirection(Shield.ActorForwardVector.Rotation());
		
		UserComp.AlterShieldEnergy(-UsageAmount * DeltaTime);

		if (UserComp.GetShieldEnergy() <= 0.0)
		{
			UserComp.SetDepleted();
		}

		Shield.ActorLocation = Player.ActorLocation;

		//Run from other player's control side to check if they are protected
		if (Player.OtherPlayer.HasControl())
		{
			if (OtherPlayerComp == nullptr)
				OtherPlayerComp = USolarFlarePlayerComponent::Get(Player.OtherPlayer);

			if (OtherPlayerComp == nullptr)
				return;

			if (Shield.BoxComp.TraceOverlappingComponent(Player.OtherPlayer.CapsuleComponent))
				CrumbSetOtherShieldProtected(true);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetOtherShieldProtected(bool bIsProtected)
	{
		OtherPlayerComp.AlterTriggerShieldProtected(bIsProtected, Player);
	}

	UFUNCTION()
	private void OnSolarFlarePlayerRecievedHit()
	{
		bWaveHit = true;
		Shield.RunImpact();
	}
};