class ALightBirdTutorialSocket : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	ASanctuaryLightBirdSocket Socket;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};