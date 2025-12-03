class ASkylineLightShowManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};