event void FMoonMarketMushroomPeopleReactionEvent(FMoonMarketMushroomPeopleReaction Data);
event void FMoonMarketMushroomPeopleReactionFinishedEvent(FMoonMarketMushroomPeopleReactionFinished Data);

class AMoonMarketMushroomPeopleManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY()
	FMoonMarketMushroomPeopleReactionEvent OnMushroomPeopleReaction;
	UPROPERTY()
	FMoonMarketMushroomPeopleReactionFinishedEvent OnMushroomPeopleReactionFinished;

	bool bMushroomPeoplesActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnMushroomPeopleReaction.AddUFunction(this, n"MushroomPeopleReactionTest");
		OnMushroomPeopleReactionFinished.AddUFunction(this, n"MushroomPeopleReactionFinishedTest");
	}

	UFUNCTION()
	private void MushroomPeopleReactionTest(FMoonMarketMushroomPeopleReaction Data)
	{
		Print(Data.Mushroom.Name + " was " + Data.ActionTag + " by " + Data.InstigatingPlayer.Name);
	}

	UFUNCTION()
	private void MushroomPeopleReactionFinishedTest(FMoonMarketMushroomPeopleReactionFinished Data)
	{
		Print(Data.Mushroom.Name + " finished reaction");
	}
};