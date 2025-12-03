class ASanctuaryWellStairsCollision : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BlockMesh;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};