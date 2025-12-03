class UPlayerDragonSignalComponent : UActorComponent
{
	UPROPERTY()
	UAnimSequence SignalAnimSequence;

	AStoneBossWeakpointCover SelectedWeakpoint;

	float SignalTime = 3.0;

	bool bSignalEnabled;
	bool bSignalSuccessful;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSignalSuccessful()
	{
		DeactivateSignal();
		bSignalSuccessful = true;
	}

	void ActivateSignal()
	{
		if (bSignalSuccessful)
			return;

		bSignalEnabled = true;
	}

	void DeactivateSignal()
	{
		bSignalEnabled = false;
	}

	void ShowSignalTutorialPrompt()
	{
		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.Action = ActionNames::PrimaryLevelAbility;
		Player.ShowTutorialPromptWorldSpace(TutorialPrompt, this, AttachOffset = FVector(0.0, 0.0, 25.0));
	}

	void RemoveSignalTutorialPrompt()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}
}