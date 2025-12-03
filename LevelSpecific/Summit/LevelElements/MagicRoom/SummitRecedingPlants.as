class ASummitRecedingPlants : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PlantRoot;

	float SmallScale = 0.15;
	float MinDist = 1000.0;

	float CurrentScale;
	float StartScale;
	
	bool bShouldShrink;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartScale = PlantRoot.GetWorldScale().X;
		CurrentScale = PlantRoot.GetWorldScale().X;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Dist1 = (Game::Mio.ActorLocation - ActorLocation).Size();
		float Dist2 = (Game::Zoe.ActorLocation - ActorLocation).Size();

		if (Dist1 < MinDist || Dist2 < MinDist)
			bShouldShrink = true;
		else
			bShouldShrink = false;

		if (bShouldShrink)
			CurrentScale = Math::FInterpConstantTo(CurrentScale, SmallScale, DeltaSeconds, 2.0);
		else
			CurrentScale = Math::FInterpConstantTo(CurrentScale, StartScale, DeltaSeconds, 2.0);

		PlantRoot.SetWorldScale3D(FVector(CurrentScale));
	}
}