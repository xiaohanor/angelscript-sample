class USanctuaryBowDarkMegaCompanionPlayerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ASanctuaryBowDarkMegaCompanion DarkMegaCompanion;
	USanctuaryBowMegaCompanionPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = USanctuaryBowMegaCompanionPlayerComponent::GetOrCreate(Player);
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
		DarkMegaCompanion.Grab();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DarkMegaCompanion.Release();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	private void ChacheRefs()
	{
		TListedActors<ASanctuaryBowDarkMegaCompanion> ListedActors;
		DarkMegaCompanion = ListedActors.Single;
	}
};