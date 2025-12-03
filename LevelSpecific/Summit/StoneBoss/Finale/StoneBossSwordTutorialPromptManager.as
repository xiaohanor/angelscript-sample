class AStoneBossSwordTutorialPromptManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(6));
#endif

	UPROPERTY(EditAnywhere)
	APlayerTrigger EndPromptsTrigger;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		EndPromptsTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		DeactivateTutorialPrompt();
	}

	UFUNCTION()
	void ActivateTutorialPrompt()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			FTutorialPrompt Prompt;
			Prompt.Action = ActionNames::PrimaryLevelAbility;
			Prompt.DisplayType = ETutorialPromptDisplay::Action;
			Prompt.MaximumDuration = 8.0;
			Prompt.Text = NSLOCTEXT("Summit", "DragonSwords", "Attack");
			if (Player.IsMio())
				Prompt.OverrideControlsPlayer = EHazeSelectPlayer::Mio;
			Game::Zoe.ShowTutorialPrompt(Prompt, this);
		}
	}

	UFUNCTION()
	void DeactivateTutorialPrompt()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.RemoveTutorialPromptByInstigator(this);
		}
	}
};