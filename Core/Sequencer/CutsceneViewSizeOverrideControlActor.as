class ACutsceneViewSizeOverrideControlActor : AHazeActor
{
	UPROPERTY(Interp)
	float OverrideViewSizePercentage = 0.5;

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		SceneView::ClearViewSizeOverride();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Game::Mio.bIsControlledByCutscene || Game::Zoe.bIsControlledByCutscene)
			SceneView::SetViewSizeOverride(OverrideViewSizePercentage);
		else
			SceneView::ClearViewSizeOverride();
	}
}