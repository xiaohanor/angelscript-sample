class ASummitShardSpawner : AHazeActorSpawnerBase
{
	UPROPERTY(DefaultComponent)
	UCapsuleComponent Collision;

	UPROPERTY(DefaultComponent)
	UHazeActorSpawnPatternEntryScenepoint EntryScenepoint;

	TArray<ASummitMetalSpawner> ActivatedMetalSpawners;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		this.JoinTeam(SummitSpawnerTags::ShardSpawnerTeam);
	}
}