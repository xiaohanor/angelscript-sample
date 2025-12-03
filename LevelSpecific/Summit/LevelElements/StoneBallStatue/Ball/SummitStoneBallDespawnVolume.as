class ASummitStoneBallDespawnVolume : AActorTrigger
{
	default ActorClasses.Add(ASummitStoneBall);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorEnter.AddUFunction(this, n"OnActorEnter");
	}

	UFUNCTION()
	private void OnActorEnter(AHazeActor Actor)
	{
		auto Ball = Cast<ASummitStoneBall>(Actor);
		if(Ball == nullptr)
			return;

		Ball.bHasHitDespawnVolume = true;
	}
};