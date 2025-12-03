event void FOnBreakObstacle();

class ATundraStickObstacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent StaticMesh;

	UPROPERTY()
	UNiagaraSystem BreakObstacleVFX;

	UPROPERTY(DefaultComponent)
	USceneComponent VFXLocation;

	UPROPERTY()
	FOnBreakObstacle OnBreakObstacle;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
	}

	UFUNCTION(BlueprintEvent)
	void BreakObstacle()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(BreakObstacleVFX, VFXLocation.WorldLocation,VFXLocation.WorldRotation);
		//DestroyActor();
		
		OnBreakObstacle.Broadcast();
	}
};