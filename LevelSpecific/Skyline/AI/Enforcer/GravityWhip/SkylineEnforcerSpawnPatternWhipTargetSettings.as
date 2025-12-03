// Applies whip settings to all spawned actors with a lower update order 
UCLASS(meta = (ShortTooltip="Applies whip settings"))
class USkylineEnforcerSpawnPatternWhipTargetSettings : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Late;
	default bLevelSpecificPattern = true;

	UPROPERTY(EditAnywhere)
	float MaximumDistance;

	UPROPERTY(EditAnywhere)
	float VisibleDistance;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		// Applying settings is deterministic, we need not include this in spawn parameters
		UHazeActorSpawnerComponent Spawner = UHazeActorSpawnerComponent::Get(Owner);
		if (ensure(Spawner != nullptr))
		{
			Spawner.OnPostSpawn.AddUFunction(this, n"OnAnyPatternSpawn");
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnAnyPatternSpawn(AHazeActor Spawn, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{
		if (IsActivePattern())
		{
			UGravityWhipTargetComponent Comp = UGravityWhipTargetComponent::GetOrCreate(Spawn);
			if(Comp != nullptr)
			{
				Comp.MaximumDistance = MaximumDistance;
				Comp.VisibleDistance = VisibleDistance;
			}
		}
	}
}
