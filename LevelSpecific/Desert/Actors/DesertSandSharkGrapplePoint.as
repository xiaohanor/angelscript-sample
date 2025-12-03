class ADesertSandSharkGrapplePoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	ASplineActor Spline;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};