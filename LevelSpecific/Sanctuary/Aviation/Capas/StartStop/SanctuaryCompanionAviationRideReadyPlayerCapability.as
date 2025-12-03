class USanctuaryCompanionAviationRideReadyPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::AviationReady);
	default DebugCategory = AviationCapabilityTags::AviationReady;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	UInfuseEssencePlayerComponent InfuseEssenceComp;
	UNiagaraComponent VFXEffect;
	UPlayerCentipedeComponent CentipedeComp;

	float VFXEssenceReadyCooldown = 0.0;
	bool bIsTutorial = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
		InfuseEssenceComp = UInfuseEssencePlayerComponent::Get(Player);
		CentipedeComp = UPlayerCentipedeComponent::Get(Player);
		TListedActors<ASanctuaryBossArenaManager> HydraManagers;
		bIsTutorial = HydraManagers.Num() == 0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (AviationComp.GetIsAviationActive())
			return false;

		if (CentipedeComp != nullptr && CentipedeComp.IsCentipedeActive())
			return false;

		bool bIgnored = false;
		if (bIsTutorial && AviationDevToggles::Tutorial::TutorialIgnoreEssence.IsEnabled())
			bIgnored = true;
		if (!bIsTutorial && AviationDevToggles::Phase1::Phase1IgnoreEssence.IsEnabled())
			bIgnored = true;
			
		if (!InfuseEssenceComp.HasEnoughOrbs() && !bIgnored)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (AviationComp.GetIsAviationActive())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AviationComp.bIsRideReady = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AviationComp.bIsRideReady = false;
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		VFXEssenceReadyCooldown -= DeltaTime;
		if (VFXEssenceReadyCooldown < 0.0 && AviationComp.CompanionReadyEffect != nullptr)
		{
			VFXEssenceReadyCooldown = 0.5;
			//Niagara::SpawnOneShotNiagaraSystemAttached(AviationComp.CompanionReadyEffect, GetCompanion().RootComponent);
		}
	}

	private AHazeCharacter GetCompanion()
	{
		if (Player.IsMio())
			return LightBirdCompanion::GetLightBirdCompanion();
		return DarkPortalCompanion::GetDarkPortalCompanion();
	}
}