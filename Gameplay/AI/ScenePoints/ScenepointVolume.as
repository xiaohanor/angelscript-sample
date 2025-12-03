class AScenepointTargetVolume : APlayerTrigger
{
	UPROPERTY(EditInstanceOnly)
	TArray<AScenepointActor> Scenepoints;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		auto ScenepointTarget = UScenepointTargetComponent::GetOrCreate(Player);
		for(AScenepointActor Scenepoint: Scenepoints)
		{
			ScenepointTarget.ScenepointContainer.Scenepoints.Add(Scenepoint.GetScenepoint());
		}
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		auto ScenepointTarget = UScenepointTargetComponent::GetOrCreate(Player);
		for(AScenepointActor Scenepoint: Scenepoints)
		{
			ScenepointTarget.ScenepointContainer.Scenepoints.RemoveSingleSwap(Scenepoint.GetScenepoint());
		}
	}
}