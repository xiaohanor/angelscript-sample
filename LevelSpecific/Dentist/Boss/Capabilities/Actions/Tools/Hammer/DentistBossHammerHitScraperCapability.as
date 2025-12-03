struct FDentistBossHammerHitScraperActivationParams
{
	float MoveDuration;
	AHazePlayerCharacter Target;
}

class UDentistBossHammerHitScraperCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;
	ADentistBossToolHammer Hammer;
	ADentistBossToolScraper Scraper;

	FDentistBossHammerHitScraperActivationParams Params;

	UDentistBossSettings Settings;

	FVector StartLocation;
	FRotator StartRotation;

	AHazePlayerCharacter TargetPlayer;

	const float TargetUpOffset = 100.0;
	const float HammerHeadRadius = 250;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		
		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossHammerHitScraperActivationParams InParams)
	{
		Params = InParams;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Params.MoveDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Hammer = Cast<ADentistBossToolHammer>(Dentist.Tools[EDentistBossTool::Hammer]);
		Scraper = Cast<ADentistBossToolScraper>(Dentist.Tools[EDentistBossTool::Scraper]);

		StartLocation = Hammer.ActorLocation;
		StartRotation = Hammer.ActorRotation;

		TargetPlayer = Params.Target;

		TargetPlayer.ApplySettings(DentistBossNoHitReactionSettings, this, EHazeSettingsPriority::Override);
		Dentist.bHammerPlayer = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{	
		for(auto Player : Game::Players)
		{
			Player.PlayCameraShake(Settings.HammerHitScraperCameraShake, this);
			Player.PlayForceFeedback(Settings.HammerHitScraperForceFeedback, false, true, this);
		}

		TargetPlayer.BlockCapabilities(n"DamageCameraShake", this);
		TargetPlayer.BlockCapabilities(n"Death", this);
		TargetPlayer.DamagePlayerHealth(Settings.HammerHitScraperDamage);
		TargetPlayer.UnblockCapabilities(n"DamageCameraShake", this);
		TargetPlayer.UnblockCapabilities(n"Death", this);

		auto ToothComp = UDentistToothPlayerComponent::Get(TargetPlayer);
		ToothComp.StruckByHammerFrame = Time::FrameNumber;

		FDentistBossEffectHandlerOnHammerHitScraperParams HitParams;
		HitParams.HookTipLocation = Scraper.ActorLocation;
		HitParams.HookTipRotation = Scraper.ActorRotation;
		HitParams.HammerHitLocation = Scraper.TipRoot.WorldLocation + FVector::UpVector * TargetUpOffset;
		HitParams.HookedPlayer = TargetPlayer;
		UDentistBossEffectHandler::Trigger_OnHammerHitScraper(Dentist, HitParams);

		TargetPlayer.ClearSettingsByInstigator(this);
		Dentist.bHammerPlayer = false;
	}

	FVector GetTargetLocation() const 
	{
		return Scraper.ActorLocation + FVector::UpVector * TargetUpOffset;
	}

	FRotator GetTargetRotation() const
	{
		return FRotator::MakeFromXZ(Dentist.ActorRightVector.RotateAngleAxis(-45, FVector::UpVector), FVector::UpVector);
	}
};