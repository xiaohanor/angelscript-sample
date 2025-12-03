struct FEnforcerHoverScenepointLOSData
{
	bool bHasLineOfSight;
	float LastCheckTime;
	FVector LastCheckedTargetLocation;
}

class UEnforcerHoverScenepointManager : UObject
{
	TMap<FName, FScenepointContainer> Scenepoints;

	uint LOSCheckFrame = 0;	
	TMap<UScenepointComponent, FEnforcerHoverScenepointLOSData> MioScenepointLOSCache;
	TMap<UScenepointComponent, FEnforcerHoverScenepointLOSData> ZoeScenepointLOSCache;

	void Register(FName TeamName, UScenepointComponent Scenepoint)
	{
		if (!Scenepoints.Contains(TeamName))
			Scenepoints.Add(TeamName, FScenepointContainer());
		Scenepoints[TeamName].Scenepoints.AddUnique(Scenepoint);
	}

	void Unregister(FName TeamName, UScenepointComponent Scenepoint)
	{
		if (Scenepoints.Contains(TeamName))
			Scenepoints[TeamName].Scenepoints.RemoveSingleSwap(Scenepoint);
	}

	bool CanCheckLineOfSight() const
	{
		if (Time::FrameNumber > LOSCheckFrame)
			return true;
		return false;
	}

	bool CheckLineOfSight(AHazePlayerCharacter Target, UScenepointComponent Scenepoint, float WithinDuration = 1.0, float WithinDistance = 400.0)
	{	
		TMap<UScenepointComponent, FEnforcerHoverScenepointLOSData>& ScenepointLOSCache = (Target.IsMio()) ? MioScenepointLOSCache : ZoeScenepointLOSCache;

		if (ScenepointLOSCache.Contains(Scenepoint))
		{
			const FEnforcerHoverScenepointLOSData& LOSData = ScenepointLOSCache[Scenepoint];
			if ((Time::GetGameTimeSince(LOSData.LastCheckTime) < WithinDuration) && 
				(Target.ActorLocation.IsWithinDist(LOSData.LastCheckedTargetLocation, WithinDistance)))
			{
				// Use cached data
				return LOSData.bHasLineOfSight;				
			}
		}

		// Need to trace, can we do that?
		if (!CanCheckLineOfSight())
			return false;

		// Trace
		LOSCheckFrame = Time::FrameNumber;
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnoreActor(Target);
		Trace.IgnoreActor(Scenepoint.Owner);
		Trace.UseLine();
		FHitResult Obstruction = Trace.QueryTraceSingle(Scenepoint.WorldLocation, Target.FocusLocation);

		// Cache result
		FEnforcerHoverScenepointLOSData NewData;
		NewData.bHasLineOfSight = !Obstruction.bBlockingHit;
		NewData.LastCheckTime = Time::GameTimeSeconds;
		NewData.LastCheckedTargetLocation = Target.ActorLocation;
		ScenepointLOSCache.Add(Scenepoint, NewData);

		if (NewData.bHasLineOfSight)
			return true;
		return false;
	}
}
