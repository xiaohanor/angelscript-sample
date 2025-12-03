// Applies follow to all spawned actors with a lower update order 
UCLASS(meta = (ShortTooltip="Applies follow to all spawned actors"))
class USkylineEnforcerSpawnPatternDisableWhippable : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Late;
	default bLevelSpecificPattern = true;

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
			UGravityWhipTargetComponent WhipTarget = UGravityWhipTargetComponent::GetOrCreate(Spawn);
			if(WhipTarget == nullptr)
				return;
			WhipTarget.Disable(this);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnAnyPatternUnspawn(AHazeActor Spawn, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{
		UGravityWhipTargetComponent WhipTarget = UGravityWhipTargetComponent::GetOrCreate(Spawn);
		if(WhipTarget == nullptr)
				return;
		WhipTarget.Enable(this);
	}
}
