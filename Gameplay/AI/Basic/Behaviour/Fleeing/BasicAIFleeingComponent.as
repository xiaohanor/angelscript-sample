event void FBasicAIOnFlee(AHazeActor Actor);

class UBasicAIFleeingComponent : UActorComponent
{
	UPROPERTY(EditInstanceOnly)
	TArray<ASplineActor> FlightSplines;

	UPROPERTY(meta = (NotBlueprintCallable))
	FBasicAIOnFlee OnFlee;

	UPROPERTY(meta = (NotBlueprintCallable))
	FBasicAIOnFlee OnFlightComplete;

	UPROPERTY(meta = (NotBlueprintCallable))
	FBasicAIOnFlee OnStopFleeing;

	bool bWantsToFlee = false;
	FSplinesContainer SplineOptions;
	bool bHasCompletedFlight = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if (RespawnComp != nullptr)
			RespawnComp.OnRespawn.AddUFunction(this, n"Reset");

		for (ASplineActor FlightSpline : FlightSplines)
		{
			AddFlightOption(FlightSpline.Spline);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void Reset()
	{
		bWantsToFlee = false;
		Owner.RemoveActorDisable(this);
		bHasCompletedFlight = false;
	}

	UFUNCTION()
	void AddFlightOption(UHazeSplineComponent Spline)
	{
		SplineOptions.Add(Spline);
	}

	UFUNCTION()
	void AddFlightOptionsFromSplineActors(TArray<ASplineActor> Splines)
	{
		for (ASplineActor Actor : Splines)
		{
			SplineOptions.Add(Actor.Spline);
		}
	}

	UFUNCTION()
	void RemoveFlightOptionsFromSplineActors(TArray<ASplineActor> Splines)
	{
		// Add instigation if needed so we don't remove splines that two or more systems want us to have
		for (ASplineActor Actor : Splines)
		{
			SplineOptions.Remove(Actor.Spline);
		}
	}

	UFUNCTION()
	void Flee()
	{
		bWantsToFlee = true;
		OnFlee.Broadcast(Cast<AHazeActor>(Owner));
	}

	UFUNCTION()
	void StopFleeing()
	{
		bWantsToFlee = false;
		OnStopFleeing.Broadcast(Cast<AHazeActor>(Owner));
	}

	void CompleteFlight()
	{
		if(bHasCompletedFlight)
			return;
		bHasCompletedFlight = true;

		// A coward dies a thousand deaths!
		Owner.AddActorDisable(this);

		// We can now be respawned
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if (RespawnComp != nullptr)
			RespawnComp.UnSpawn();

		OnFlightComplete.Broadcast(Cast<AHazeActor>(Owner));
	}
}
