class ASanctuaryBossLoopingPlatformDebris : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	TArray<UStaticMesh> MeshArray;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};