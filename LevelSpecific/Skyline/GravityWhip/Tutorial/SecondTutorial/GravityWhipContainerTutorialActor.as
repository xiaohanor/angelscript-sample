class AGravityWhipContainerTutorialActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent GrabLocation;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};