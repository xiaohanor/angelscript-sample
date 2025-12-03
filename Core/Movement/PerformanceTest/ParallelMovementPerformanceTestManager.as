#if TEST
const FConsoleCommand Command_SpawnParallelTest_Simple("Haze.Movement.Parallel.PerformanceTest_Spawn", n"SpawnParallelMovementPerformanceTest");

enum EParallelTestMovementPerformanceTestResolverType
{
	Simple = 0,
	Stepping = 1,
	MAX = 2,
};

UCLASS(NotBlueprintable)
class UParallelMovementPerformanceTestManager : UActorComponent
{
	TArray<AActor> SpawnedActors;
};

void SpawnParallelMovementPerformanceTest(TArray<FString> Arguments)
{
	auto Manager = UParallelMovementPerformanceTestManager::GetOrCreate(Game::Mio);

	for(auto SpawnedActor : Manager.SpawnedActors)
		SpawnedActor.DestroyActor();

	Manager.SpawnedActors.Reset();

	const int SpawnCountPerSide = SpawnParallelTest_GetSpawnCountPerSide(Arguments);
	const int Spacing = SpawnParallelTest_GetSpacing(Arguments);

	FVector MioLocation = Game::Mio.ActorLocation;
	FRotator MioRotation = Game::Mio.ControlRotation;

	MioRotation.Pitch = 0;
	MioLocation += MioRotation.ForwardVector * (((SpawnCountPerSide * float(Spacing)) / 4));

	for(int X = 0; X < SpawnCountPerSide; X++)
	{
		for(int Y = 0; Y < SpawnCountPerSide; Y++)
		{
			FVector Offset = FVector(X * Spacing, Y * Spacing, 50);
			Offset = MioRotation.RotateVector(Offset);
			AActor Actor = SpawnActor(AParallelMovementPerformanceTest, MioLocation + Offset, MioRotation);

			if(Actor != nullptr)
				Manager.SpawnedActors.Add(Actor);
		}
	}

	Print(f"Spawned {Manager.SpawnedActors.Num()} ParallelMovement PerformanceTest actors.");
};

int SpawnParallelTest_GetSpawnCountPerSide(TArray<FString> Arguments)
{
	const int DEFAULT_SPAWN_COUNT = 10;

	if(Arguments.Num() == 0)
		return DEFAULT_SPAWN_COUNT;

	FString Argument = Arguments[0];
	if(!Argument.IsNumeric())
		return DEFAULT_SPAWN_COUNT;

	return String::Conv_StringToInt(Argument);
};

int SpawnParallelTest_GetSpacing(TArray<FString> Arguments)
{
	const int DEFAULT_SPAWN_SPACING = 100;

	if(Arguments.Num() < 2)
		return DEFAULT_SPAWN_SPACING;

	FString Argument = Arguments[1];
	if(!Argument.IsNumeric())
		return DEFAULT_SPAWN_SPACING;

	return String::Conv_StringToInt(Argument);
};
#endif