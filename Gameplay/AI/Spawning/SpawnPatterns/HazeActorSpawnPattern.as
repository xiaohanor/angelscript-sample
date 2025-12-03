struct FHazeActorSpawnSlot
{
	TArray<FHazeActorSpawnParameters> SpawnParameters;
}

struct FHazeActorSpawnBatch
{
	TMap<TSubclassOf<AHazeActor>, FHazeActorSpawnSlot> Batch;

	void Spawn(UHazeActorSpawnPattern SpawningPattern, TSubclassOf<AHazeActor> SpawnClass, int NumSpawn = 1)
	{
		FHazeActorSpawnSlot& Slot = Batch.FindOrAdd(SpawnClass);

		for (int i = 0; i < NumSpawn; i++)
		{
			FHazeActorSpawnParameters Params;
			Params.Spawner = SpawningPattern;
			Params.Location = SpawningPattern.WorldLocation;
			Params.Rotation = SpawningPattern.WorldRotation;
			Slot.SpawnParameters.Add(Params);
		}
	}
}

enum ESpawnPatternUpdateOrder
{
	First,
	Early,
	Normal,
	Late,
	Last
}

event void FOnActivatedSpawnPatternSignature(UHazeActorSpawnPattern Pattern);

UCLASS(Abstract, Meta = (HideCategories = "Rendering Activation Cooking Physics LOD Collision"))
class UHazeActorSpawnPattern : USceneComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

#if EDITOR
	// Set by details customization so visualization can use the same sorting
	int VisualOffsetOrder = 0;
#endif	

	// Only active patters will be updated
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = SpawnPattern)
	bool bStartActive = true;

	bool bLevelSpecificPattern = false;

	// Pattern will be updated based on this order, lowest order first. As a spawn batch is accumulated in update order 
	// higher order patterna will be able to tweak and override spawning done by lower order patterns.
	// I.e. if you want to modify spawned actors, you should have a high order, if you don't care use a low order
	ESpawnPatternUpdateOrder UpdateOrder = ESpawnPatternUpdateOrder::Early;

	// True if this pattern could spawn actors given the right properties
	bool bCanEverSpawn = false;

	FOnActivatedSpawnPatternSignature OnActivated;

	private bool bHasInitializedCanSpawn = false;
	private bool bCanSpawn = false;
	private TInstigated<bool> bIsActivePattern;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bIsActivePattern.SetDefaultValue(bStartActive);

		TArray<TSubclassOf<AHazeActor>> SpawnClasses;
		GetSpawnClasses(SpawnClasses);
		bCanSpawn = (SpawnClasses.Num() > 0);
		bHasInitializedCanSpawn = true;
	}

	// Update spawn pattern and set any actor it wants to spawn. This is only called on control side.
	// Any spawn parameters you set on entries in the spawn batch will be replicated.
	void UpdateControlSide(float DeltaTime, FHazeActorSpawnBatch& SpawnBatch)
	{
	}

	// True when spawn pattern is has finished spawning actors. When completed it will not be updated. 
	bool IsCompleted() const
	{
		return false;		
	}

	// Called on both sides in network when an actor has been spawned by this pattern
	void OnSpawn(AHazeActor SpawnedActor)
	{
	}

	// Called on both sides in network when an actor spawned by this pattern is ready for respawn
	void OnUnspawn(AHazeActor UnspawnedActor)
	{
	}

	// Adds any classes this spawn pattern can spawn, used to set up spawn pools
	void GetSpawnClasses(TArray<TSubclassOf<AHazeActor>>& OutSpawnClasses) const
	{
	} 

	bool CanSpawn() const
	{
		if (bHasInitializedCanSpawn)
			return bCanSpawn;
		TArray<TSubclassOf<AHazeActor>> SpawnClasses;
		GetSpawnClasses(SpawnClasses);
		return (SpawnClasses.Num() > 0);
	}

	bool NeedsUpdate() const
	{
		return CanSpawn() && !IsCompleted(); 
	}

	bool ShouldStartActive() const
	{
		return bStartActive;
	}

	UFUNCTION(BlueprintPure)
	bool IsActivePattern() const
	{
		return bIsActivePattern.Get();
	}

	UFUNCTION()
	void ActivatePattern(FInstigator Instigator, EInstigatePriority Prio = EInstigatePriority::Low)
	{
		bool bWasActive = IsActivePattern();
		bIsActivePattern.Apply(true, Instigator, Prio);
		if(!bWasActive)
			OnActivated.Broadcast(this);
	}

	UFUNCTION()
	void DeactivatePattern(FInstigator Instigator, EInstigatePriority Prio = EInstigatePriority::Low)
	{
		bIsActivePattern.Apply(false, Instigator, Prio);
	}

	UFUNCTION()
	void ClearPatternActivation(FInstigator Instigator)
	{
		bIsActivePattern.Clear(Instigator);
	}

	// Reset pattern to original state, as defined by each pattern.
	void ResetPattern()
	{
	}
}

