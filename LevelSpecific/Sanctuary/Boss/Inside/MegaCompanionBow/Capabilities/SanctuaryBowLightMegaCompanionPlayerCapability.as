class USanctuaryBowLightMegaCompanionPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ASanctuaryBowLightMegaCompanion LightMegaCompanion;
	USanctuaryBowMegaCompanionPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = USanctuaryBowMegaCompanionPlayerComponent::GetOrCreate(Player);
		ChacheRefs();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!PlayerComp.bMegaCompanionsActivated)
			return false;

		if (!WasActionStarted(ActionNames::WeaponAim))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!PlayerComp.bMegaCompanionsActivated)
			return true;

		if (WasActionStopped(ActionNames::WeaponAim))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ChacheRefs();
		LightMegaCompanion.StartChargeArrow();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LightMegaCompanion.StopChargeArrow();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	
	}

	private void ChacheRefs()
	{
		TListedActors<ASanctuaryBowLightMegaCompanion> ListedActors;
		LightMegaCompanion = ListedActors.Single;
	}
};