class ABattlefieldLevelScriptActor : AHazeLevelScriptActor
{
	UFUNCTION()
	void SetHoverboardTutorialsActive()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			UBattlefieldHoverboardTrickComponent::Get(Player).bCanRunTutorial = true;
	}

	UFUNCTION()
	void SetHoverboardSpeedEffect(bool bIsOn)
	{
		for (AHazePlayerCharacter Player : Game::Players)
			UBattlefieldHoverboardComponent::Get(Player).bCanRunSpeedEffect = bIsOn;
	}

	UFUNCTION()
	void SnapFreefallCameraOnSpawn()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			UBattlefieldHoverboardFreeFallingComponent::Get(Player).bSnapCamera = true;
	}

	UFUNCTION()
	void SetFreefallCameraFromIntroCustcene()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			UBattlefieldHoverboardFreeFallingComponent::Get(Player).bIsComingFromCutscene = true;
	}

	UFUNCTION()
	void HideHoverboard()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			UBattlefieldHoverboardComponent::Get(Player).HideHoverboardForCutscene();
	}

	UFUNCTION()
	void SetHoverboardTrailEffectVisibleState(bool bIsHidden)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			auto Comp = UBattlefieldHoverboardComponent::Get(Player);
			Comp.Hoverboard.BP_SetTrailEffectHiddenState(bIsHidden);
		}
	}

	UFUNCTION()
	void InitializePlayerCavernLoopSpeed()
	{
		for (auto Player : Game::Players)
		{
			UBattlefieldHoverboardComponent::Get(Player).bHasQueuedCavernSpeedInitialization = true;
		}
	}
};