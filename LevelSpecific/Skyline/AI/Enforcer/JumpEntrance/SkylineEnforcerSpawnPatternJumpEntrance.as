// Applies jump scenepoints to all spawned actors with a lower update order 
UCLASS(meta = (ShortTooltip="Applies jump scenepoints to all spawned actors"))
class USkylineEnforcerSpawnPatternJumpEntrance : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Late;
	default bLevelSpecificPattern = true;

	UPROPERTY(EditAnywhere)
	TArray<ASkylineEnforcerJumpEntranceScenepoint> JumpScenepoints;

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
			USkylineEnforcerJumpEntranceComponent Comp = USkylineEnforcerJumpEntranceComponent::GetOrCreate(Spawn);
			Comp.Scenepoints = JumpScenepoints;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnAnyPatternUnspawn(AHazeActor Spawn, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{
		USkylineEnforcerJumpEntranceComponent Comp = USkylineEnforcerJumpEntranceComponent::GetOrCreate(Spawn);
		Comp.Scenepoints.Empty();
	}
}
