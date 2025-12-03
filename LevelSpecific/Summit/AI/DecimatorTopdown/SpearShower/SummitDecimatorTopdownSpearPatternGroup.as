class ASummitDecimatorTopdownSpearPatternGroup : AScenepointActor
{
	UPROPERTY(EditAnywhere, meta = (EditCondition = "GroupDistanceInterval == 0", EditConditionHides))
	float GroupFractionInterval;
	
	UPROPERTY(EditAnywhere, meta = (EditCondition = "GroupFractionInterval == 0", EditConditionHides))
	float GroupDistanceInterval;

	UPROPERTY(EditAnywhere)
	float GroupSpawnDelayInterval;

	UPROPERTY(EditAnywhere)
	TArray<ASummitDecimatorTopdownSpearSplineActor> Splines;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		// Triggered on delete all array entries
		if (Splines.Num() == 0)
		{
			// Check for all attached child spline actors
			TArray<AActor> Actors;
			GetAttachedActors(Actors);
			for (int i = Actors.Num()-1; i >= 0; i--)
			{
				AActor Spline = Actors[i];
				Splines.Add(Cast<ASummitDecimatorTopdownSpearSplineActor>(Spline));
			}
			
			// Sort by name
			Splines.Sort();
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{		
	}

	// Sort by name FString
	int opCmp(ASummitDecimatorTopdownSpearPatternGroup Other) const
	{
		if(this.GetActorNameOrLabel() > Other.GetActorNameOrLabel())
			return 1;
		else
			return -1;
	}

}