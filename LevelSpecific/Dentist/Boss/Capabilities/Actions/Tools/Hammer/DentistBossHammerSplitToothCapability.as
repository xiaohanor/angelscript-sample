class UDentistBossHammerSplitToothCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;
	ADentistBossToolHammer Hammer;
	ADentistBossToolScraper Scraper;

	UDentistBossSettings Settings;

	AHazePlayerCharacter TargetPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		
		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Hammer = Cast<ADentistBossToolHammer>(Dentist.Tools[EDentistBossTool::Hammer]);
		Scraper = Cast<ADentistBossToolScraper>(Dentist.Tools[EDentistBossTool::Scraper]);

		TargetPlayer = Scraper.RestrainedPlayer.Value;
		
		TargetPlayer.PlayCameraShake(Settings.ToothSplitCameraShake, this);
		TargetPlayer.PlayForceFeedback(Settings.ToothSplitForceFeedback, false, true, this);

		TargetPlayer.ApplySettings(DentistBossNoHitReactionSettings, this, EHazeSettingsPriority::Override);
		TargetPlayer.BlockCapabilities(n"DamageCameraShake", this);
		TargetPlayer.BlockCapabilities(n"Death", this);
		TargetPlayer.DamagePlayerHealth(Settings.ToothSplitDamage);
		TargetPlayer.UnblockCapabilities(n"DamageCameraShake", this);
		TargetPlayer.UnblockCapabilities(n"Death", this);
		TargetPlayer.ClearSettingsByInstigator(this);

		auto SplitComp = UDentistToothSplitComponent::Get(TargetPlayer);
		SplitComp.bShouldSplit = true;
		Timer::SetTimer(this, n"ApplyPoITowardsSplitTooth", 0.2);

		Scraper.RestrainedPlayer.Reset();

		FDentistBossEffectHandlerOnHammerSplitPlayerParams HitParams;
		HitParams.Player = TargetPlayer;
		UDentistBossEffectHandler::Trigger_OnHammerSplitPlayer(Dentist, HitParams);
		
		DetachFromActionQueue();
	}

	UFUNCTION()
	void ApplyPoITowardsSplitTooth()
	{
		auto SplitComp = UDentistToothSplitComponent::Get(TargetPlayer);
		SplitComp.bShouldSplit = true;
		FHazePointOfInterestFocusTargetInfo PoIInfo;
		PoIInfo.SetFocusToActor(SplitComp.SplitToothAI);
		TargetPlayer.ApplyPointOfInterest(this, PoIInfo, Settings.SplitToothPoISettings, 2.0, EHazeCameraPriority::Medium);
	}
};