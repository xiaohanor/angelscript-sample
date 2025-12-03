event void FMoonMarketMolesActivatedEvent();
event void FMoonMarketMoleReactionEvent(FMoonMarketMoleReaction Data);
event void FMoonMarketMoleReactionFinishedEvent(FMoonMarketMoleReactionFinished Data);

namespace MoonMarketMole
{
	AMoonMarketMoleManager GetManager()
	{
		return TListedActors<AMoonMarketMoleManager>().GetSingle();
	}
}

class AMoonMarketMoleManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY()
	FMoonMarketMolesActivatedEvent OnMolesActivated;
	UPROPERTY()
	FMoonMarketMoleReactionEvent OnMoleReaction;
	UPROPERTY()
	FMoonMarketMoleReactionFinishedEvent OnMoleReactionFinished;

	bool bMolesActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnMoleReaction.AddUFunction(this, n"MoleReactionTest");
		OnMoleReactionFinished.AddUFunction(this, n"MoleReactionFinishedTest");
	}

	UFUNCTION()
	private void MoleReactionTest(FMoonMarketMoleReaction Data)
	{
		Print(Data.Mole.Name + " was " + Data.ActionTag + " by " + Data.InstigatingPlayer.Name);
	}

	UFUNCTION()
	private void MoleReactionFinishedTest(FMoonMarketMoleReactionFinished Data)
	{
		Print(Data.Mole.Name + " finished reaction");
	}

	UFUNCTION(DevFunction)
	void SetMolesWalkActive()
	{
		if(!bMolesActive)
		{
			OnMolesActivated.Broadcast();
			bMolesActive = true;
		}
	}
};

UFUNCTION(BlueprintCallable)
void MoonMarketSetMolesWalkActive()
{
	TListedActors<AMoonMarketMoleManager>().Single.SetMolesWalkActive();
}