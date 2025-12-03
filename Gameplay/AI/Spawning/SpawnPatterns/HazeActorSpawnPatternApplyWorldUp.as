// Set world up of all spawned actors
UCLASS(meta = (ShortTooltip="Set world up of all spawned actors."))
class UHazeActorSpawnPatternApplyWorldUp : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Late;

	UPROPERTY(EditAnywhere, Category = "SpawnPattern")
	FVector WorldUp = FVector::UpVector * -1.0;

	UPROPERTY(EditAnywhere, Category = "SpawnPattern")
	EInstigatePriority Priority = EInstigatePriority::Normal;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		// World up is deterministic, so no need to replicate
		UHazeActorSpawnerComponent Spawner = UHazeActorSpawnerComponent::Get(Owner);
		if (ensure(Spawner != nullptr))
		{
			Spawner.OnPostSpawn.AddUFunction(this, n"OnAnyPatternSpawn");
			Spawner.OnPostUnspawn.AddUFunction(this, n"OnAnyPatternUnspawn");
		}
	}

	UFUNCTION()
	private void OnAnyPatternUnspawn(AHazeActor UnspawnedActor, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{
		UnspawnedActor.ClearGravityDirectionOverride(this);
	}

	UFUNCTION()
	private void OnAnyPatternSpawn(AHazeActor SpawnedActor, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{
		SpawnedActor.OverrideGravityDirection(-WorldUp, this, Priority);
	}

	void UpdateControlSide(float DeltaTime, FHazeActorSpawnBatch& SpawnBatch) override
	{
		Super::UpdateControlSide(DeltaTime, SpawnBatch);
		
		// Align spawn rotation with our world up so they'll spawn correctly rotated 
		// instead of spawning and then having to teleport in OnAnyPatternSpawn
		for (auto& Entry : SpawnBatch.Batch)
		{
			for (FHazeActorSpawnParameters& Params : Entry.Value.SpawnParameters)
			{
				Params.Rotation = FRotator::MakeFromZX(UpVector, Params.Rotation.ForwardVector);
			}
		}
	}
}
