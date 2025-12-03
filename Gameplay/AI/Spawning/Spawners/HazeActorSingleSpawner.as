UCLASS(Meta = (HighlightPlacement))
class AHazeActorSingleSpawner : AHazeActorSpawnerBase
{
	UPROPERTY(DefaultComponent)
	UHazeActorSpawnPatternSingle SpawnPatternSingle;

	UPROPERTY(DefaultComponent)
	UHazeActorSpawnPatternEntryScenepoint EntryScenepoint;
}
