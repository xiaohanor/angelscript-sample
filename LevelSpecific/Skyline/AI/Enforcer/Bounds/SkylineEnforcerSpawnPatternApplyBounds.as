// Applies enforcer bounds to all spawned actors with a lower update order 
UCLASS(meta = (ShortTooltip="Applies enforcer bounds to all spawned actors"))
class USkylineEnforcerSpawnPatternApplyBounds : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Late;
	default bLevelSpecificPattern = true;

	UPROPERTY(EditAnywhere, Category = "SpawnPattern")
	ASkylineEnforcerBoundsVolume EnforcerBounds;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if (EnforcerBounds == nullptr)
		{
			// Uninitialized, this will not have any effect
			DeactivatePattern(this, EInstigatePriority::Override);
			return;
		}

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
			USkylineEnforcerBoundsComponent BoundsComp = USkylineEnforcerBoundsComponent::GetOrCreate(Spawn);
			BoundsComp.CurrentBounds = EnforcerBounds;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnAnyPatternUnspawn(AHazeActor Spawn, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{
		USkylineEnforcerBoundsComponent BoundsComp = USkylineEnforcerBoundsComponent::GetOrCreate(Spawn);
		BoundsComp.CurrentBounds = nullptr;
	}
}
