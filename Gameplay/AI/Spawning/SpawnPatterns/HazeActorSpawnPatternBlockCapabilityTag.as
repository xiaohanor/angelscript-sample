// Blocks a specified capability tag for any actor spawned.
UCLASS(meta = (ShortTooltip="Blocks a specified capability tag for any actor spawned."))
class UHazeActorSpawnPatternBlockCapabilityTag : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Early;

	// Block this tag.
	UPROPERTY(EditAnywhere, Category = "SpawnPattern")
	FName BlockedTag;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		UHazeActorSpawnerComponent OwnSpawner = UHazeActorSpawnerComponent::Get(Owner);
		OwnSpawner.OnPostSpawn.AddUFunction(this, n"OnPostSpawn");
		OwnSpawner.OnPostUnspawn.AddUFunction(this, n"OnPostUnspawn");
	}

	UFUNCTION()
	private void OnPostUnspawn(AHazeActor UnspawnedActor, UHazeActorSpawnerComponent Spawner,
	                           UHazeActorSpawnPattern SpawningPattern)
	{
		if (Spawner.Owner != Owner)
			return;
		UnspawnedActor.UnblockCapabilities(BlockedTag, this);
	}

	UFUNCTION()
	private void OnPostSpawn(AHazeActor SpawnedActor, UHazeActorSpawnerComponent Spawner,
	                         UHazeActorSpawnPattern SpawningPattern)
	{
		if (Spawner.Owner != Owner)
			return;
		SpawnedActor.BlockCapabilities(BlockedTag, this);
	}
}