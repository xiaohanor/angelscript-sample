// Applies grappling settings to all spawned actors with a lower update order 
UCLASS(meta = (ShortTooltip="Applies grapple settings"))
class USkylineEnforcerSpawnPatternGrappleTargetSettings : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Late;
	default bLevelSpecificPattern = true;

	UPROPERTY(EditAnywhere)
	float MaximumDistance;

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
			UGravityBladeGrappleComponent Comp = UGravityBladeGrappleComponent::GetOrCreate(Spawn);
			if(Comp != nullptr)
			{
				Comp.MaximumDistanceFromPlayer = MaximumDistance;
				Comp.MaximumDistance = MaximumDistance;
			}
		}
	}
}
