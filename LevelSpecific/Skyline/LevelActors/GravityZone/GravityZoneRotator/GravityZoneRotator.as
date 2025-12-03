class AGravityZoneRotator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent Camera;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

}