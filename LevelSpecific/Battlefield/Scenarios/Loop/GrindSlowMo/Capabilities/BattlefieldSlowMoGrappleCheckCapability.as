class UBattlefieldSlowMoGrappleCheckCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	TPerPlayer<bool> bBothPlayersGrappling;

	ABattlefieldSlowMoGrappleManager GrappleManager;
	float MaxTime = 1.3;
	bool bCompleted;
	bool bRemovedHealthSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GrappleManager = Cast<ABattlefieldSlowMoGrappleManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (bCompleted)
			return false;

		if (!GrappleManager.bBeginSlowMo)
			return false;

		if (GrappleManager.bGrappleCompleted)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bCompleted)
			return true;

		if (Time::GameTimeSeconds > MaxTime)
			return true;

		if (!GrappleManager.bBeginSlowMo)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MaxTime = Time::GameTimeSeconds + MaxTime;
		GrappleManager.AnyPlayerGrappleClearSplineRespawn();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GrappleManager.CompleteDoubleGrapple();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player.IsAnyCapabilityActive(PlayerMovementTags::Grapple) || Player.IsAnyCapabilityActive(n"BattlefieldGrind"))
			{
				bBothPlayersGrappling[Player] = true;
				
				if (!bRemovedHealthSettings)
				{
					bRemovedHealthSettings = true;
					for (AHazePlayerCharacter CurrentPlayer : Game::Players)
						CurrentPlayer.ClearSettingsWithAsset(GrappleManager.HealthSettings, GrappleManager);
				}
			}
		}

		if (bBothPlayersGrappling[Game::Mio] && bBothPlayersGrappling[Game::Zoe])
		{
			bCompleted = true;
		}
	}
};