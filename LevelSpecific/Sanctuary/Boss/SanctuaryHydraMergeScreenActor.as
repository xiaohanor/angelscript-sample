class ASanctuaryHydraMergeScreenActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor FullScreenCamera;

	float MinDist = 4000.0;
	float EvolveDist = 100.0;
	bool bMerged = false;
	bool bFlying = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// if (!bMerged && Game::Mio.GetDistanceTo(Game::Zoe) < MinDist)
		// 	ActivateFullScreen();

		// if (bMerged && Game::Mio.GetDistanceTo(Game::Zoe) > MinDist + 100.0)
		// 	ResetFullScreen();

		// if (Game::Mio.GetDistanceTo(Game::Zoe) < EvolveDist && !bFlying)
		// 	StartFlying();
	}

	private void ActivateFullScreen()
	{
		bMerged = true;
		Game::Zoe.ActivateCamera(FullScreenCamera, 2.0, this, EHazeCameraPriority::Low);
		Game::Mio.ActivateCamera(FullScreenCamera, 2.0, this, EHazeCameraPriority::Low);
		Camera::BlendToFullScreenUsingProjectionOffset(Game::Zoe, this, 2.0, 2.0);

		PrintToScreenScaled("MERGED", 1.0);
	}

	UFUNCTION()
	void ResetFullScreen()
	{
		bMerged = false;
		Camera::BlendToSplitScreenUsingProjectionOffset(this, 2.0);
		Game::Zoe.DeactivateCameraByInstigator(this, 2.0);
		Game::Mio.DeactivateCameraByInstigator(this, 2.0);
	}

	UFUNCTION()
	void StartFlying()
	{
		bFlying = true;

		for (auto Player : Game::Players)
		{
			UMedallionPlayerComponent MedallionComp = UMedallionPlayerComponent::GetOrCreate(Player);	
			MedallionComp.StartMedallionFlying();
		}
	}
};