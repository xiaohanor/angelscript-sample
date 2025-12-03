class ASummitTeenDragonFruit : ATeenDragonEatableObject
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}
};