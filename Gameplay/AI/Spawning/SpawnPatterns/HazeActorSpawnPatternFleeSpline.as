// Adds splines to flee along to spawned actors from patterns of lower update order
UCLASS(meta = (ShortTooltip="Adds splines to flee along to spawned actors."))
class UHazeActorSpawnPatternFleeSpline : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Late;

	UPROPERTY(EditAnywhere, Category = "SpawnPattern")
	TArray<ASplineActor> Splines;

	// Causes all actors spawned by our spawner to want to flee
	UFUNCTION(DevFunction)
	void Flee()
	{
		UHazeActorSpawnerComponent Spawner = UHazeActorSpawnerComponent::Get(Owner);
		if ((Spawner == nullptr) || (Spawner.SpawnedActorsTeam == nullptr))
			return;

		for (AHazeActor Spawn : Spawner.SpawnedActorsTeam.GetMembers())
		{
			UBasicAIFleeingComponent FleeComp = (Spawn != nullptr) ? UBasicAIFleeingComponent::Get(Spawn) : nullptr;
			if (FleeComp != nullptr)
				FleeComp.Flee();
		}
	}

	UFUNCTION()
	void StopFleeing()
	{
		UHazeActorSpawnerComponent Spawner = UHazeActorSpawnerComponent::Get(Owner);
		if ((Spawner == nullptr) || (Spawner.SpawnedActorsTeam == nullptr))
			return;

		for (AHazeActor Spawn : Spawner.SpawnedActorsTeam.GetMembers())
		{
			UBasicAIFleeingComponent FleeComp = (Spawn != nullptr) ? UBasicAIFleeingComponent::Get(Spawn) : nullptr;
			if (FleeComp != nullptr)
				FleeComp.StopFleeing();
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if (Splines.Num() == 0)
			DeactivatePattern(this, EInstigatePriority::Override);

		// We'll get all splines, so this is deterministic, no need to replicate
		UHazeActorSpawnerComponent Spawner = UHazeActorSpawnerComponent::Get(Owner);
		if (ensure(Spawner != nullptr))
		{
			Spawner.OnPostSpawn.AddUFunction(this, n"OnAnyPatternSpawn");
			Spawner.OnPostUnspawn.AddUFunction(this, n"OnAnyPatternUnspawn");
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnAnyPatternSpawn(AHazeActor Spawn, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{
		UBasicAIFleeingComponent FleeComp = UBasicAIFleeingComponent::Get(Spawn);
		if (FleeComp != nullptr)
			FleeComp.AddFlightOptionsFromSplineActors(Splines);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnAnyPatternUnspawn(AHazeActor Spawn, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{
		UBasicAIFleeingComponent FleeComp = UBasicAIFleeingComponent::Get(Spawn);
		if (FleeComp != nullptr)
			FleeComp.RemoveFlightOptionsFromSplineActors(Splines);
	}
}
