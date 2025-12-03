UCLASS()
class USummitMageCritterSpawnPattern : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Early;
	default bCanEverSpawn = true;
	default bLevelSpecificPattern = true;

	// Class to spawn
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = SpawnPattern)
	TSubclassOf<AHazeActor> SpawnClass;

	bool bDoneSpawning;
	FVector SpawnLocation;
	USummitMageSettings MageSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		if (!SpawnClass.IsValid())
		{
			// Uninitialized, this will not have any effect
			DeactivatePattern(this, EInstigatePriority::Override);
			return;
		}
		MageSettings = USummitMageSettings::GetSettings(Cast<AHazeActor>(Owner));
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

		if(bDoneSpawning)
			return;
		
		for(int i = 0; i < MageSettings.CritterWaveSize; i++)
		{
			WorldLocation = SpawnLocation + FVector(Math::RandRange(-200, 200), Math::RandRange(-200, 200), 0.0);
			SpawnBatch.Spawn(this, SpawnClass);		
		}
		
		bDoneSpawning = true;
	}

	bool IsCompleted() const override
	{
		return bDoneSpawning;
	}

	void OnSpawn(AHazeActor SpawnedActor) override
	{
		Super::OnSpawn(SpawnedActor);
		SpawnedActor.JoinTeam(SummitMageTags::SummitMageCritterTeam);
	}

	void OnUnspawn(AHazeActor UnspawnedActor) override
	{
		Super::OnUnspawn(UnspawnedActor);
		UnspawnedActor.LeaveTeam(SummitMageTags::SummitMageCritterTeam);
	}
}
