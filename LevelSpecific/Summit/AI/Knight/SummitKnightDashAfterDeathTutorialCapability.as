class USummitKnightDashAfterDeathTutorialCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Tutorial);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Gameplay;

	AHazePlayerCharacter TutorialPlayer;
	USummitKnightComponent KnightComp;
	float RespawnTime = BIG_NUMBER;
	bool bHasBeenShownTutorial = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TutorialPlayer = Game::Mio;
		KnightComp = USummitKnightComponent::Get(Owner);

		// Bind respawn event on both player so we can clean up KnightComp.bDeathCouldHaveBeenDashAvoided
		for (AHazePlayerCharacter Player : Game::Players)
		{
			UPlayerRespawnComponent::Get(Player).OnPlayerRespawned.AddUFunction(this, n"OnPlayerRespawn");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			UPlayerRespawnComponent::Get(Player).OnPlayerRespawned.UnbindObject(this);
		}
	}

	UFUNCTION()
	private void OnPlayerRespawn(AHazePlayerCharacter RespawnedPlayer)
	{
		bool bDashTutorialRelevant = KnightComp.bDeathCouldHaveBeenDashAvoided[RespawnedPlayer];
		KnightComp.bDeathCouldHaveBeenDashAvoided[RespawnedPlayer] = false;

		if (RespawnedPlayer != TutorialPlayer)
			return;
		if (!bDashTutorialRelevant)
			return;
		RespawnTime = Time::GameTimeSeconds;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (bHasBeenShownTutorial)
			return false;
		if (Time::GameTimeSeconds < RespawnTime + 1.0)
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
		FTutorialPrompt DashTutorial;
		DashTutorial.Action = ActionNames::MovementDash;
		DashTutorial.Mode = ETutorialPromptMode::RemoveWhenPressed;
		DashTutorial.Text = NSLOCTEXT("Ruby Knight", "Dash Tutorial", "Dash");

		// Press to dash
		TutorialPlayer.ShowTutorialPrompt(DashTutorial, this);

		// Once only
		bHasBeenShownTutorial = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};