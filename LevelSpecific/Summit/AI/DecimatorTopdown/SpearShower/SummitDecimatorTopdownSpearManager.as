event void FOnSpearManagerSpawnParametersUpdated(float SpawnDelayInterval);

class ASummitDecimatorTopdownSpearManager : AScenepointActor
{
	UPROPERTY(EditAnywhere)
	TArray<ASummitDecimatorTopdownSpearPatternGroup> SplineGroups;

	ASummitDecimatorTopdownSpearSplineActor CurrentSpline;
	float CurrentFractionInterval;
	float CurrentSpawnDelayInterval;
	float CurrentFraction;
	bool bIsBatchSpawning = false;

	int CurrentSplineIndex = 0;
	int CurrentGroupIndex = 0;

	FOnSpearManagerSpawnParametersUpdated OnSpawnParamsUpdated;

	access PrivateWithSpawnCapability = private, USummitDecimatorTopdownPatternSpearSpawnerCapability;
	access:PrivateWithSpawnCapability bool bIsSpawningSpears = false;

	bool IsSpawningSpears() const
	{
		return bIsSpawningSpears;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		// Triggered on delete all array entries
		if (SplineGroups.Num() == 0)
		{
			// Check for all attached child spline actors
			TArray<AActor> Actors;
			GetAttachedActors(Actors);
			for (int i = Actors.Num()-1; i >= 0; i--)
			{
				AActor Group = Actors[i];
				SplineGroups.Add(Cast<ASummitDecimatorTopdownSpearPatternGroup>(Group));
			}
			
			// Sort by name
			SplineGroups.Sort();
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{			
		CurrentGroupIndex = 0;
		SetUpPatternParams();
	}

	bool HasNextSpawnLocation()
	{	
		return CurrentFraction <= 1.0 && CurrentSplineIndex < SplineGroups[CurrentGroupIndex].Splines.Num();
	}

	FVector GetNextSpawnLocation()
	{
		FVector Location = CurrentSpline.Spline.GetWorldLocationAtSplineFraction(CurrentFraction);
		CurrentFraction += CurrentFractionInterval;
		
		// When spline end is reached, the initial point of next spline is set as new location
		if (CurrentFraction > 1.0)
		{
			CurrentFraction = 0;
			CurrentSplineIndex++;
			if (CurrentSplineIndex < SplineGroups[CurrentGroupIndex].Splines.Num())
			{
				CurrentSpline = SplineGroups[CurrentGroupIndex].Splines[CurrentSplineIndex];
				CalculateCurrentFractionInterval();
			}
		}
		return Location;
	}

	FVector GetCurrentSpawnLocation() const
	{
		return CurrentSpline.Spline.GetWorldLocationAtSplineFraction(CurrentFraction);
	}

	void Reset()
	{
		CurrentSplineIndex = 0;
		CurrentFraction = 0;
		CurrentSpline = SplineGroups[CurrentGroupIndex].Splines[0];
		CalculateCurrentFractionInterval();
	}
	
	private void CalculateCurrentFractionInterval()
	{
		// Assumes either fraction or distance interval is > 0 and SplineLength as well.
		if (SplineGroups[CurrentGroupIndex].GroupFractionInterval > 0)
			CurrentFractionInterval = SplineGroups[CurrentGroupIndex].GroupFractionInterval;
		else if (SplineGroups[CurrentGroupIndex].GroupDistanceInterval > 0)
			CurrentFractionInterval = SplineGroups[CurrentGroupIndex].GroupDistanceInterval / CurrentSpline.Spline.SplineLength;
	}

	private void SetUpPatternParams()
	{
		bool bEnsure = devEnsure(CurrentGroupIndex < SplineGroups.Num());
		bEnsure = devEnsure(SplineGroups[CurrentGroupIndex].Splines.Num() > 0);

		CurrentSpawnDelayInterval = SplineGroups[CurrentGroupIndex].GroupSpawnDelayInterval;
		bIsBatchSpawning = SplineGroups[CurrentGroupIndex].GroupSpawnDelayInterval <= 0 ? true : false;
		
		// Set Current Spline
		CurrentSplineIndex = 0;
		CurrentSpline = SplineGroups[CurrentGroupIndex].Splines[0];			

		CalculateCurrentFractionInterval();
	}

	// Advances GroupIndex
	void NextPattern()
	{
		CurrentGroupIndex++;
		if (CurrentGroupIndex >= SplineGroups.Num())
		{
			CurrentGroupIndex = 0;
		}

		Reset();
		SetUpPatternParams();
	}

	// Temp dev functions

	UFUNCTION(DevFunction)
	void DevResetCurrentPattern()
	{
		Reset();
	}

	UFUNCTION(DevFunction)
	void DevNextPattern()
	{
		NextPattern();
		OnSpawnParamsUpdated.Broadcast(CurrentSpawnDelayInterval); // message spawner capability
	}


}

