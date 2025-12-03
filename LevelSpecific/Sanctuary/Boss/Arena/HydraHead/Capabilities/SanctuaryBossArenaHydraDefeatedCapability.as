class USanctuaryBossArenaHydraDefeatedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;
	ASanctuaryBossArenaHydra Hydra;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Hydra = Cast<ASanctuaryBossArenaHydra>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Hydra.IsDefeated())
			return false;
		if (IsMioOrZoeAviating())
			return false;
		// if (IsMioOrZoeSkydiving())
		// 	return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	bool IsMioOrZoeAviating() const
	{
		return Game::Mio.IsAnyCapabilityActive(AviationCapabilityTags::AviationRiding) || Game::Zoe.IsAnyCapabilityActive(AviationCapabilityTags::AviationRiding); 
	}
	
	bool IsMioOrZoeSkydiving() const
	{
		return Game::Mio.IsAnyCapabilityActive(PlayerMovementTags::Skydive) || Game::Zoe.IsAnyCapabilityActive(PlayerMovementTags::Skydive) || Game::Mio.IsAnyCapabilityActive(PlayerMovementTags::AirMotion) || Game::Zoe.IsAnyCapabilityActive(PlayerMovementTags::AirMotion);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// PrintToScreenScaled("ACTIVATED", 5.0, ColorDebug::Magenta, 4.0);
		if (CompanionAviation::bProgressToPhase2)
			Hydra.OnArenaBossDefeated.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > 10.0)
			PrintToScreenScaled("HYDRA DEFEATED " + ActiveDuration + " seconds ago - should progress?", 0.0, FLinearColor::Green, 4.0);
	}
};