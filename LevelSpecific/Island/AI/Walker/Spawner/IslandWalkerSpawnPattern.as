UCLASS(meta = (ShortTooltip="Walker dedicated spawn pattern"))
class UIslandWalkerSpawnPattern : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Early;
	default bCanEverSpawn = true;
	default bLevelSpecificPattern = true;

	UIslandWalkerSpawnerComponent WalkerSpawnerComp;
	UIslandWalkerSettings Settings;

	// Class to spawn
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = SpawnPattern)
	TSubclassOf<AHazeActor> SpawnClass;

	AHazeActor HazeOwner;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		// Abstract classes can't be spawned
		if (SpawnClass.IsValid() && SpawnClass.Get().IsAbstract())
			SpawnClass = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		HazeOwner = Cast<AHazeActor>(Owner);
		WalkerSpawnerComp = UIslandWalkerSpawnerComponent::Get(Owner);
		Settings = UIslandWalkerSettings::GetSettings(Cast<AHazeActor>(Owner));
	}

	void GetSpawnClasses(TArray<TSubclassOf<AHazeActor>>& OutSpawnClasses) const override
	{
		if (!SpawnClass.IsValid())
			return;
		OutSpawnClasses.AddUnique(SpawnClass);
	}

	void UpdateControlSide(float DeltaTime, FHazeActorSpawnBatch& SpawnBatch) override
	{
		Super::UpdateControlSide(DeltaTime, SpawnBatch);

		// Spawn all pending minions at given sockets turned away from actor center
		if (WalkerSpawnerComp.PendingSpawnPoints.Num() > 0)
		{
			SpawnBatch.Spawn(this, SpawnClass, WalkerSpawnerComp.PendingSpawnPoints.Num());
			TArray<FHazeActorSpawnParameters>& SpawnParams = SpawnBatch.Batch[SpawnClass].SpawnParameters;
			for (int i = 0; i < SpawnParams.Num(); i++)
			{
				SpawnParams[i].Location = WalkerSpawnerComp.PendingSpawnPoints[i].WorldLocation;
				SpawnParams[i].Rotation = WalkerSpawnerComp.PendingSpawnPoints[i].WorldRotation;
			}
			WalkerSpawnerComp.PendingSpawnPoints.Reset();
		}
	}

	void OnSpawn(AHazeActor SpawnedActor) override
	{
		Super::OnSpawn(SpawnedActor);
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(SpawnedActor);
		FVector SpawnFwd = RespawnComp.SpawnParameters.Rotation.ForwardVector;

		// Regular movement impulse does not work due to delay in between this and first movement, use custom buzzer spawn impulse instead
		UIslandBuzzerWalkerComponent::Get(SpawnedActor).SpawnImpulse = SpawnFwd * Settings.SpawningLaunchSpeed;
	
		UIslandWalkerEffectHandler::Trigger_OnSpawnedMinion(HazeOwner, FIslandWalkerSpawnedMinionEventData(RespawnComp.SpawnParameters.Location, SpawnFwd));
	}
}
