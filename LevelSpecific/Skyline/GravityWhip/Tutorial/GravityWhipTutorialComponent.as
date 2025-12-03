class UGravityWhipTutorialComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	FTutorialPromptChain PromptGrabSlingChain;

	bool bGrabSlingComplete = false;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptGrab;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptSling;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptDrag;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptDragVertical;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptDragHorizontal;

	UPROPERTY(EditAnywhere)
	FVector AttachOffset = FVector::ZeroVector;

	UPROPERTY(EditAnywhere)
	float ScreenSpaceOffset = 60.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	//	RemoveTutorial();
	}

	UFUNCTION(BlueprintCallable)
	void ShowTutorial()
	{
		auto Player = Cast<AHazePlayerCharacter>(Owner);
		Player.UnblockCapabilities(n"GravityWhipTutorial", this);
	}

	UFUNCTION(BlueprintCallable)
	void RemoveTutorial()
	{
		auto Player = Cast<AHazePlayerCharacter>(Owner);
		Player.BlockCapabilities(n"GravityWhipTutorial", this);
	}
}