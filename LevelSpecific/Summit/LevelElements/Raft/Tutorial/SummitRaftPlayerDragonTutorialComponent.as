delegate void FSummitRaftPlayerTutorialCompleteEvent();
delegate void FSummitRaftPlayerTutorialTimeoutEvent();

struct FSummitRaftPlayerHoldTutorialData
{
	FSummitRaftPlayerTutorialCompleteEvent OnCompleted;
	FSummitRaftPlayerTutorialTimeoutEvent OnTimedout;
	FTutorialPrompt Prompt;
	float HoldDuration;
	float MaxDuration = MAX_flt;
}

class USummitRaftPlayerDragonTutorialComponent : UActorComponent
{
	bool bHasActivePrompt = false;

	AHazePlayerCharacter Player;

	FSummitRaftPlayerHoldTutorialData Data;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		UPlayerHealthComponent::Get(Player).OnFinishDying.AddUFunction(this, n"OnPlayerFinishedDying");
	}

	UFUNCTION()
	private void OnPlayerFinishedDying()
	{
		RemoveTutorial();
	}

	void ShowTutorialPromptUntilHeldForDuration(FTutorialPrompt Prompt, float HoldDuration, float MaxDuration = -1, FSummitRaftPlayerTutorialCompleteEvent OnCompleted = FSummitRaftPlayerTutorialCompleteEvent(), FSummitRaftPlayerTutorialTimeoutEvent OnTimedout = FSummitRaftPlayerTutorialTimeoutEvent())
	{
		FSummitRaftPlayerHoldTutorialData NewData;
		NewData.HoldDuration = HoldDuration;
		NewData.Prompt = Prompt;
		NewData.MaxDuration = MaxDuration;

		NewData.OnCompleted = OnCompleted;
		NewData.OnTimedout = OnTimedout;

		Data = NewData;

		bHasActivePrompt = true;
		Player.ShowTutorialPrompt(Prompt, this);
	}

	void ShowTutorialPromptWorldSpaceUntilHeldForDuration(FTutorialPrompt Prompt,
		float HoldDuration,
		float MaxDuration = -1,
		USceneComponent AttachComponent = nullptr,
		FVector AttachOffset = FVector(0.0, 0.0, 176.0),
		float ScreenSpaceOffset = 100.0,
		FName AttachSocket = NAME_None,
		FSummitRaftPlayerTutorialCompleteEvent OnCompleted = FSummitRaftPlayerTutorialCompleteEvent(),
		FSummitRaftPlayerTutorialTimeoutEvent OnTimedout = FSummitRaftPlayerTutorialTimeoutEvent())
	{
		FSummitRaftPlayerHoldTutorialData NewData;
		NewData.HoldDuration = HoldDuration;
		NewData.Prompt = Prompt;
		NewData.MaxDuration = MaxDuration;

		NewData.OnCompleted = OnCompleted;
		NewData.OnTimedout = OnTimedout;

		Data = NewData;

		bHasActivePrompt = true;
		Player.ShowTutorialPromptWorldSpace(Prompt, this, AttachComponent, AttachOffset, ScreenSpaceOffset, AttachSocket);
	}

	void RemoveTutorial()
	{
		bHasActivePrompt = false;
		Player.RemoveTutorialPromptByInstigator(this);
	}
};