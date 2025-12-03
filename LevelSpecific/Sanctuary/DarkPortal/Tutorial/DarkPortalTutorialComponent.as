class UDarkPortalTutorialComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	FTutorialPromptChain PromptAimFireChain;

	bool bAimFireComplete = false;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptAim;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptFire;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptGrab;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptPush;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	//	RemoveTutorial();
	}

	UFUNCTION(BlueprintCallable)
	void ShowTutorial()
	{
		auto Player = Cast<AHazePlayerCharacter>(Owner);
		Player.UnblockCapabilities(n"DarkPortalTutorial", this);
	}

	UFUNCTION(BlueprintCallable)
	void RemoveTutorial()
	{
		auto Player = Cast<AHazePlayerCharacter>(Owner);
		Player.BlockCapabilities(n"DarkPortalTutorial", this);
	}
}