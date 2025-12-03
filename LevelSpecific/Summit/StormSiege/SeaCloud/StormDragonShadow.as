class AStormDragonShadow : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkelMesh;
	default SkelMesh.SetWorldScale3D(FVector(8));

	//TArray<ASummitCloud> SummitClouds;

	float Speed = 16500.0;

	float MinDist = 16500.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		SetActorHiddenInGame(true);
		//GetAllActorsOfClass(SummitClouds);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActorLocation += ActorForwardVector * Speed * DeltaSeconds;

		TListedActors<ASummitCloud> SummitClouds;
		for (ASummitCloud Cloud : SummitClouds)
		{
			if ((Cloud.ActorLocation - ActorLocation).Size() < MinDist)
				Cloud.SendCloudUp();
		}
	}

	UFUNCTION()
	void ActivateShadowMove()
	{
		SetActorTickEnabled(true);
		SetActorHiddenInGame(false);

		// FHazeFocusTarget FocusTarget;
		// FocusTarget.LocalOffset = FVector(76000.0, 0.0, 12000.0);
		// FocusTarget.FocusActor(this);
		// FApplyPointOfInterestSettings Settings;
		// Settings.InputPauseTime = 1.5;
		// Settings.bClearOnInput = true;
		// Settings.Duration = 3.0;

		// for (AHazePlayerCharacter Player : Game::Players)
		// 	Player.ApplyPointOfInterest(this, FocusTarget, Settings, 3.5);
	}

	UFUNCTION()
	void DeactivateShadow()
	{
		SetActorHiddenInGame(true);
		SetActorTickEnabled(false);
		
		for (AHazePlayerCharacter Player : Game::Players)
			Player.ClearPointOfInterestByInstigator(this);
	}
}