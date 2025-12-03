class ASpaceWalkEscapeShip : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Ship;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};