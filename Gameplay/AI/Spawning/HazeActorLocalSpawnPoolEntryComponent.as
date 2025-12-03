event void FHazeActorLocalSpawnPoolEntryOnSpawned(AHazeActor Actor);
event void FHazeActorLocalSpawnPoolEntryOnUnspawned(AHazeActor Actor);

/**
 * Interface for working with UHazeActorLocalSpawnPoolComponent.
 * Bind OnSpawned and OnUnspawned instead of using BeginPlay and EndPlay.
 * Call Unspawn instead of DestroyActor.
 */
UCLASS(NotBlueprintable)
class UHazeActorLocalSpawnPoolEntryComponent : UActorComponent
{
	access Internal = private, UHazeActorLocalSpawnPoolComponent;

	UPROPERTY(EditAnywhere)
	bool bDisableWhenUnspawned = true;

	UPROPERTY(BlueprintReadOnly)
	FHazeActorLocalSpawnPoolEntryOnSpawned OnSpawned;

	UPROPERTY(BlueprintReadOnly)
	FHazeActorLocalSpawnPoolEntryOnUnspawned OnUnspawned;

	private AHazeActor HazeOwner;
	access:Internal UHazeActorLocalSpawnPoolComponent SpawnPoolComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
	}

	/**
	 * Notify the pool component that we want to be unspawned, broadcast OnUnspawned and disable owner. 
	 */
	void Unspawn()
	{
		SpawnPoolComp.UnSpawn(HazeOwner);
	}

	access:Internal
	void InternalOnSpawned(UHazeActorLocalSpawnPoolComponent InSpawnPoolComp)
	{
		SpawnPoolComp = InSpawnPoolComp;

		if(bDisableWhenUnspawned)
			Owner.RemoveActorDisable(this);

		OnSpawned.Broadcast(HazeOwner);
	}

	access:Internal
	void InternalOnUnspawned()
	{
		OnUnspawned.Broadcast(HazeOwner);
		
		if(bDisableWhenUnspawned)
			Owner.AddActorDisable(this);
	}
};