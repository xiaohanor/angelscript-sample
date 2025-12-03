class UIslandRedBlueStickyGrenadeTutorialComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	FTutorialPromptChain PromptFireDetonateChain;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptFire;
	
	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptDetonate;

	float LastTimeDetonatePromptShown;
	bool bFirstPromptShown = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION(BlueprintCallable)
	void ShowTutorial()
	{
		auto Player = Cast<AHazePlayerCharacter>(Owner);
		Player.UnblockCapabilities(n"IslandRedBlueStickyGrenadeTutorial", this);
	}

	UFUNCTION(BlueprintCallable)
	void RemoveTutorial()
	{
		auto Player = Cast<AHazePlayerCharacter>(Owner);
		Player.BlockCapabilities(n"IslandRedBlueStickyGrenadeTutorial", this);
	}
};