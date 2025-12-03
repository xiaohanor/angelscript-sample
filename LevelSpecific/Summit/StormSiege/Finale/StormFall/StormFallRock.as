struct FStormFallRockParams
{
	UPROPERTY()
	AStormFallRockSpawner Spawner;

	UPROPERTY(EditAnywhere)
	float FallSpeed = 2000.0;

	UPROPERTY(EditAnywhere)
	float TotalFallDistance = 15000.0;
}

class AStormFallRock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	FStormFallRockParams Params;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActorLocation += ActorUpVector * Params.FallSpeed * DeltaSeconds;
		float Dist = (ActorLocation - Params.Spawner.ActorLocation).DotProduct(Params.Spawner.ActorUpVector);
		if (Dist > Params.TotalFallDistance)
			DestroyActor();
	}

	UFUNCTION()
	void DeactivateFall()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	void ActivateFall()
	{
		SetActorTickEnabled(true);
	}
}