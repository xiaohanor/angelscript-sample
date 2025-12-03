class UIslandWalkerRespawnPointsCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PlayerRespawning");

	default TickGroup = EHazeTickGroup::AfterGameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UIslandWalkerComponent WalkerComp;
	UIslandWalkerPhaseComponent PhaseComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WalkerComp = UIslandWalkerComponent::Get(Owner);
		PhaseComp = UIslandWalkerPhaseComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PhaseComp.Phase == EIslandWalkerPhase::Intro)
			return false;
		if (PhaseComp.Phase == EIslandWalkerPhase::IntroEnd)
			return false;
		if (PhaseComp.Phase == EIslandWalkerPhase::Destroyed)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PhaseComp.Phase == EIslandWalkerPhase::Destroyed)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WalkerComp.ArenaLimits.EnableAllRespawnPoints(this);
		for (AHazePlayerCharacter Player : Game::Players)
		{
			UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::Get(Player);
			RespawnComp.ResetStickyRespawnPoints();
			RespawnComp.ApplyRespawnOverrideDelegate(this, FOnRespawnOverride(this, n"HandleRespawn"), EInstigatePriority::High);
		}
	}

	UFUNCTION()
	private bool HandleRespawn(AHazePlayerCharacter Player, FRespawnLocation& OutLocation)
	{
		OutLocation.RespawnPoint = WalkerComp.ArenaLimits.GetBestRespawnPoint(Player);
		if (OutLocation.RespawnPoint == nullptr)
			return false;
		OutLocation.RespawnTransform = OutLocation.RespawnPoint.GetPositionForPlayer(Player);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		WalkerComp.ArenaLimits.DisbleAllRespawnPoints(this);
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.ClearRespawnPointOverride(this);
		}
	}
};