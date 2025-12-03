// Applies landing scenepoints to all spawned actors with a lower update order 
UCLASS(meta = (ShortTooltip="Applies landing scenepoints to all spawned actors"))
class USkylineEnforcerSpawnPatternScenepointEntrance : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Late;
	default bLevelSpecificPattern = true;

	UPROPERTY(EditAnywhere)
	TArray<AScenepointActor> LandingScenepoints;

	private int ScenepointIndex = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		// Applying settings is deterministic, we need not include this in spawn parameters
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
		if (IsActivePattern())
		{
			USkylineEnforcerScenepointEntranceComponent Comp = USkylineEnforcerScenepointEntranceComponent::GetOrCreate(Spawn);

			if(LandingScenepoints.Num() == 0)
				return;

			Comp.LandingScenepoint = LandingScenepoints[ScenepointIndex];
			ScenepointIndex++;
			if(ScenepointIndex >= LandingScenepoints.Num())
				ScenepointIndex = 0;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnAnyPatternUnspawn(AHazeActor Spawn, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{
		USkylineEnforcerScenepointEntranceComponent Comp = USkylineEnforcerScenepointEntranceComponent::GetOrCreate(Spawn);
		Comp.LandingScenepoint = nullptr;
	}
}
