class AMoonMarketBalloonManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	TArray<AMoonMarketFollowBalloon> BallonsToActivate;
	TArray<AMoonMarketFollowBalloon> TotalBallons;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (BallonsToActivate.Num() == 0)
		{
			TotalBallons = TListedActors<AMoonMarketFollowBalloon>().Array;
			for (AMoonMarketFollowBalloon Balloon : TotalBallons)
			{
				if (Balloon.bActivateAfterTownComplete)
				{
					BallonsToActivate.Add(Balloon);
					Balloon.AddActorDisable(this);
				}
			}
			SetActorTickEnabled(false);
		}	
	}

	UFUNCTION()
	void ActivateBalloons()
	{
		for (AMoonMarketFollowBalloon Balloon : BallonsToActivate)
		{
			if (Balloon.bActivateAfterTownComplete)
			{
				Balloon.RemoveActorDisable(this);
			}
		}
	}
};