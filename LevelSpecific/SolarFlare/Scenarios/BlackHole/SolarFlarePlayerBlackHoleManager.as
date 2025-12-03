class ASolarFlarePlayerBlackHoleManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY(EditAnywhere)
	AActor FallTarget;

	UPROPERTY(EditAnywhere)
	ASolarFlareButtonMashLauncher ButtonMashLauncher;

	UPROPERTY(EditAnywhere)
	ASolarFlareDestructibleCover DestructibleCover;
	
	UPROPERTY(EditAnywhere)
	TPerPlayer<AFocusCameraActor> FocusCamerasRunning;
	UPROPERTY(EditAnywhere)
	TPerPlayer<AFocusCameraActor> FocusCamerasBlackHole;
	UPROPERTY(EditAnywhere)
	AFocusCameraActor FullScreenCamera;

	UFUNCTION()
	void StartBlackHoleIntro()
	{
		// for (AHazePlayerCharacter Player : Game::Players)
		// {
		// 	Player.ActivateCamera(FocusCamerasRunning[Player], 1.5, this, EHazeCameraPriority::High);
		// 	Player.ActivateCamera(FullScreenCamera, 1.5, this, EHazeCameraPriority::High);
		// }
	}

	UFUNCTION()
	void StartBlackHoleSuckIn()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.DeactivateCameraByInstigator(ButtonMashLauncher);
			auto Comp = USolarFlarePlayerBlackHoleComponent::Get(Player);
			Comp.EnableBlackHole();
			Comp.FallTarget = FallTarget;
			Player.ActivateCamera(FullScreenCamera, 3.5, this, EHazeCameraPriority::High);
		}
	}
};