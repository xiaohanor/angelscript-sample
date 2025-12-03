class ATowerCubeManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger PlayerTrigger;

	TPerPlayer<bool> PlayersInside;

	TArray<ATowerCube> Cubes; 

	int CubesActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Actor : AttachedActors)
		{
			auto Cube = Cast<ATowerCube>(Actor);
			if (Cube != nullptr)
			{
				Cubes.Add(Cube);
			}
		}

		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		PlayerTrigger.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		PlayersInside[Player] = true;
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		PlayersInside[Player] = false;

		if (!PlayersInside[Player] && !PlayersInside[Player.OtherPlayer])
		{
			for (ATowerCube Cube : Cubes)
			{
				Cube.DeactivateCube();
			}
		}
	}
};