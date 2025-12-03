class ACrystalObstacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	float DeathRadius = 110;

	float LifeTime = 2.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player.GetDistanceTo(this) <= DeathRadius)
				Player.KillPlayer();
		}

		// Debug::DrawDebugSphere(ActorLocation, DeathRadius, 14, FLinearColor::Red, 5.0);

		ActorLocation -= FVector::UpVector * 1000.0 * DeltaSeconds;
		LifeTime -= DeltaSeconds;

		if (LifeTime <= 0.0)
			DestroyActor();
	}
};