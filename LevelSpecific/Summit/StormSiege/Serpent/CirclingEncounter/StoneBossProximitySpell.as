class AStoneBossProximitySpell : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	UNiagaraSystem Explosion;

	float LifeTime = 2.0;

	FVector StartScale;
	float TargetScaleMultiplier = 12.0;
	float CurrentScaleMultiplier = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartScale = ActorScale3D;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentScaleMultiplier = Math::FInterpConstantTo(CurrentScaleMultiplier, TargetScaleMultiplier, DeltaSeconds, TargetScaleMultiplier / 2.0);
		SetActorScale3D(StartScale * CurrentScaleMultiplier);

		LifeTime -= DeltaSeconds;

		if (LifeTime <= 0.0)
		{
			Niagara::SpawnOneShotNiagaraSystemAtLocation(Explosion, ActorLocation, WorldScale = FVector(5.0));
			DestroyActor();
		}
	}
};