class ASummitExplodyFruitDespawnVolume : AActorTrigger
{
	default ActorClasses.Add(ASummitExplodyFruit);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorEnter.AddUFunction(this, n"OnActorEnter");
	}

	UFUNCTION()
	private void OnActorEnter(AHazeActor Actor)
	{
		auto Fruit = Cast<ASummitExplodyFruit>(Actor);
		if(Fruit == nullptr)
			return;

		Fruit.bHasHitDespawnVolume = true;
	}
};