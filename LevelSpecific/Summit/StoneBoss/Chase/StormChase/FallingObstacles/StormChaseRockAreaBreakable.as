class AStormChaseRockAreaBreakable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent RockExplosion;
	default RockExplosion.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	USerpentSpikeSeedResponseComponent ResponseComp;

	TArray<AStormChaseFallingRockObstacle> RockObstacles;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);

		for (AActor Actor : AttachedActors)
		{
			auto Rock = Cast<AStormChaseFallingRockObstacle>(Actor);
			if (Rock != nullptr)
				RockObstacles.Add(Rock);
		}

		ResponseComp.OnSerpentSpikeSeedImpact.AddUFunction(this, n"OnSerpentSpikeSeedImpact");
	}

	UFUNCTION()
	private void OnSerpentSpikeSeedImpact()
	{
		UStormChaseRockAreaBreakableEffectHandler::Trigger_OnRockAreaDestroyed(this, FRockAreaDestroyedParams(ActorLocation));
		MeshComp.SetHiddenInGame(true);
		MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		ActivateFallingRocks();
		RockExplosion.Activate();
	}

	void ActivateFallingRocks()
	{
		for (AStormChaseFallingRockObstacle Rock : RockObstacles)
		{
			UStormChaseFallingObstacleComponent::Get(Rock).StartFalling();
		}
	}
};