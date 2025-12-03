enum EMeltdownBossPhaseThreePiranhaTargetingType
{
	// Randomized position in the arena
	RandomPosition,
	// Target a random player
	RandomPlayer,
	// Always target mio
	Mio,
	// Always target zoe
	Zoe,
}

struct FMeltdownBossPhaseThreePiranhaConfig
{
	UPROPERTY()
	int ProjectileCount = 10;
	UPROPERTY()
	float StartLaunchingDelay = 1.0;
	UPROPERTY()
	float LaunchInterval = 1.0;

	UPROPERTY()
	EMeltdownBossPhaseThreePiranhaTargetingType TargetingType = EMeltdownBossPhaseThreePiranhaTargetingType::RandomPosition;
	// Predict the player's velocity forward in time for the targeting (only used when targeting player)
	UPROPERTY()
	float TargetingPredictionTime = 0.0;
}

struct FMeltdownBossPhaseThreePiranhaSpawnData
{
	FVector TargetLocation;
	AHazePlayerCharacter TargetPlayer;
}

class AMeltdownBossPhaseThreePiranhaSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent SpawnLocation;

	UPROPERTY(DefaultComponent)
	UBoxComponent TargetBox;
	default TargetBox.BoxExtent = FVector(500, 500, 0.1);

	AHazePlayerCharacter Player;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AMeltdownBossPhaseThreePiranhas> PiranhaPortalSpawn;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
	}

	UFUNCTION(DevFunction)
	void StartAttack(FMeltdownBossPhaseThreePiranhaConfig Config)
	{
		if (!HasControl())
			return;

		TArray<FMeltdownBossPhaseThreePiranhaSpawnData> SpawnData;
		for (int i = 0; i < Config.ProjectileCount; ++i)
		{
			FMeltdownBossPhaseThreePiranhaSpawnData Spawn;
			Spawn.TargetLocation = TargetBox.WorldTransform.TransformPosition(FVector(
				Math::RandRange(-TargetBox.BoxExtent.X, TargetBox.BoxExtent.X),
				Math::RandRange(-TargetBox.BoxExtent.Y, TargetBox.BoxExtent.Y),
				Math::RandRange(-TargetBox.BoxExtent.Z, TargetBox.BoxExtent.Z),
			));

			if (Config.TargetingType == EMeltdownBossPhaseThreePiranhaTargetingType::RandomPlayer)
				Spawn.TargetPlayer = Game::GetPlayer(EHazePlayer(Math::RandRange(0, 1)));
			else if (Config.TargetingType == EMeltdownBossPhaseThreePiranhaTargetingType::Mio)
				Spawn.TargetPlayer = Game::Mio;
			else if (Config.TargetingType == EMeltdownBossPhaseThreePiranhaTargetingType::Zoe)
				Spawn.TargetPlayer = Game::Zoe;
			else
				Spawn.TargetPlayer = nullptr;

			SpawnData.Add(Spawn);
		}

		NetSpawnProjectilesForAttack(Config, SpawnData);
	}

	UFUNCTION(NetFunction)
	void NetSpawnProjectilesForAttack(FMeltdownBossPhaseThreePiranhaConfig Config, TArray<FMeltdownBossPhaseThreePiranhaSpawnData> SpawnData)
	{
		for (int i = 0, Count= SpawnData.Num(); i < Count; ++i)
		{
			FMeltdownBossPhaseThreePiranhaSpawnData Spawn = SpawnData[i];

			auto Piranha = Cast<AMeltdownBossPhaseThreePiranhas>(
				SpawnActor(PiranhaPortalSpawn, Spawn.TargetLocation, FRotator()));
			Piranha.PlayerTarget = Spawn.TargetPlayer;
			Piranha.TargetPredictionTime = Config.TargetingPredictionTime;
			Timer::SetTimer(Piranha, n"StartAttack", Config.StartLaunchingDelay + Config.LaunchInterval * i);
		}
	}
};