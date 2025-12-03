class USummitStoneBeastZapperRecoveryBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Focus);

	USummitStoneBeastZapperSettings Settings;
	UBasicAIHealthComponent HealthComp;

	AAISummitStoneBeastZapper Zapper;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitStoneBeastZapperSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		Zapper = Cast<AAISummitStoneBeastZapper>(Owner);
		Zapper.RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}


	UFUNCTION()
	private void OnRespawn()
	{
		Zapper.VulnerableSpotLight.SetVisibility(false);
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.VulnerabilityDuration)
			return true;
		if (HealthComp.IsDead())
			return true;
		
		return false;
	}

	bool bIsExiting = false;
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Zapper.VFXShieldTemp.SetHiddenInGame(true);

		AnimComp.RequestFeature(FeatureTagCrystalCrawler::Locomotion, SummitCrystalCrawlerSubTags::VulnerableEnter, EBasicBehaviourPriority::Minimum, this);
		Zapper.VulnerableSpotLight.SetVisibility(true);

		bIsExiting = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Zapper.VulnerableSpotLight.SetVisibility(false);
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bIsExiting && ActiveDuration > Settings.VulnerabilityDuration - 1.0)
		{
			AnimComp.RequestFeature(FeatureTagCrystalCrawler::Locomotion, SummitCrystalCrawlerSubTags::VulnerableExit, EBasicBehaviourPriority::Minimum, this);
			bIsExiting = true;
		}
	}
}