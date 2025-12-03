// Base class for patterns activating another spawner 
UCLASS(Abstract)
class UHazeActorSpawnPatternActivateOtherSpawner : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Early;

	// This spawner will be activated when conditions are met.
	UPROPERTY(EditAnywhere, Category = "SpawnPattern")
	AHazeActorSpawnerBase OtherSpawner; 

	private UHazeActorSpawnerComponent OtherSpawnerComp;

	UPROPERTY(EditAnywhere, AdvancedDisplay, Category = "SpawnPattern")
	EInstigatePriority ActivationPriority = EInstigatePriority::Normal;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OtherSpawnerComp = (OtherSpawner != nullptr) ? UHazeActorSpawnerComponent::Get(OtherSpawner) : nullptr;
		if (OtherSpawnerComp == nullptr)
		{
			DeactivatePattern(this, EInstigatePriority::Override);
			return;
		}
	}

	// This should maintain update even though it won't spawn anything, as it can complete after spawning patterns are completed.
	bool NeedsUpdate() const override
	{
		return !IsCompleted(); 
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	protected void NetActivateOtherSpawner()
	{
		OtherSpawnerComp.ActivateSpawner(this, ActivationPriority);
	}
}
