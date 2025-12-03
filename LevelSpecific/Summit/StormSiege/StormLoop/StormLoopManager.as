class AStormLoopManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.WorldScale3D = FVector(10.0);

	UPROPERTY(EditAnywhere)
	ARespawnPoint SpawnPoint;

	UPROPERTY(EditAnywhere)
	AStaticCameraActor StormLoopCamera;

	UPROPERTY(EditAnywhere)
	AStormDragonIntro StormDragonIntro;

	// UPROPERTY()
	// UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StormDragonIntro.SetActorHiddenInGame(true);
	}

	UFUNCTION()
	void ActivateStormLoop()
	{
		StormDragonIntro.SetActorHiddenInGame(false);

		TListedActors<ASummitCloud> Clouds;

		//GetAllActorsOfClass(Clouds);

		for (ASummitCloud Cloud : Clouds)
			Cloud.SetActorHiddenInGame(true);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			UPlayerAdultDragonComponent Comp = UPlayerAdultDragonComponent::Get(Player);
			Comp.SetStormState(EAdultDragonStormState::StormLoop);
			Player.TeleportToRespawnPoint(SpawnPoint, this);
			// Player.ApplyCameraSettings(CameraSettings, 1, this, EHazeCameraPriority::High);
		}
		
		AHazePlayerCharacter ControlPlayer;

		if (Game::Mio.HasControl())
			ControlPlayer = Game::Mio;
		else
			ControlPlayer = Game::Zoe;
	
		ControlPlayer.ApplyViewSizeOverride(this ,EHazeViewPointSize::Fullscreen);
		ControlPlayer.ActivateCamera(StormLoopCamera, 1.5, this);
		StormDragonIntro.ActivateAttackingState();
	}
}