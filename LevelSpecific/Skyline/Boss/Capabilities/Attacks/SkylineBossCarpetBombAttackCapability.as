class USkylineBossCarpetBombAttackCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossAttack);
	default CapabilityTags.Add(SkylineBossTags::SkylineBossCarpetBombAttack);

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Boss.IsPhaseActive(ESkylineBossPhase::Second))
			return false;

		if (DeactiveDuration < 15.0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TListedActors<ASkylineBossCarpetBomber> CarpetBombers;
		for (auto CarpetBomber : CarpetBombers)
			CarpetBomber.BeginBombRun(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
}