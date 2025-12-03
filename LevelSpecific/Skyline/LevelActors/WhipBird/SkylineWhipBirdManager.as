class ASkylineWhipBirdManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	TArray<USceneComponent> Targets;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void AddTarget(USceneComponent Target)
	{
		Targets.Add(Target);
	}

	void RemoveTarget(USceneComponent Target)
	{
		Targets.Remove(Target);
	}
};