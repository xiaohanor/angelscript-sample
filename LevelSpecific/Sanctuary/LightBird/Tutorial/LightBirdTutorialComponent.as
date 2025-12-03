class ULightBirdTutorialComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	FTutorialPromptChain PromptAimFireChain;

	bool bAimFireComplete = false;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptAim;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptFire;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptIlluminate;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	//	RemoveTutorial();
	}

	UFUNCTION(BlueprintCallable)
	void ShowTutorial()
	{
		auto Player = Cast<AHazePlayerCharacter>(Owner);
		Player.UnblockCapabilities(n"LightBirdTutorial", this);
	}

	UFUNCTION(BlueprintCallable)
	void RemoveTutorial()
	{
		auto Player = Cast<AHazePlayerCharacter>(Owner);
		Player.BlockCapabilities(n"LightBirdTutorial", this);
	}
}