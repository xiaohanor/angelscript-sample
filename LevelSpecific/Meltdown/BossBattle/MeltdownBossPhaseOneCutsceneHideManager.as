class AMeltdownBossPhaseOneCutsceneHideManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	TArray<AMeltdownBossCubeGrid> HideGrid;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION(BlueprintCallable)
	void HideMeshes()
	{
		for (AMeltdownBossCubeGrid MeshToHide : HideGrid)
		{
			MeshToHide.AddActorDisable(this);
		}
	}
};