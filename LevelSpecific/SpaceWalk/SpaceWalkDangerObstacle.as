class ASpaceWalkDangerObstacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mine;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};