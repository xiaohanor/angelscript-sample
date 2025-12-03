UCLASS(Meta = (HighlightPlacement))
class AHazeActorWaveSpawner : AHazeActorSpawnerBase
{
	UPROPERTY(DefaultComponent)
	UHazeActorSpawnPatternWave SpawnPatternWave;

	UPROPERTY(DefaultComponent)
	UHazeActorSpawnPatternEntryScenepoint EntryScenepoint;
}
