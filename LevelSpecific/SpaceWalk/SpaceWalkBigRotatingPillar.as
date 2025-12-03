class ASpaceWalkBigRotatingPillar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	URotatingMovementComponent Rotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}
};