class ASpaceWalkLaserWallForceFeedback : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UForceFeedbackComponent LaserFF;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintCallable)
	void StartForceFeedback()
	{
		LaserFF.Play();
	}
};