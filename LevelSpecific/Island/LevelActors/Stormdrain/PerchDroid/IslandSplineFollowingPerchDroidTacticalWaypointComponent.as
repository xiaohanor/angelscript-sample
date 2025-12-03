class UIslandSplineFollowingPerchDroidTacticalWaypointComponent : UHazeEditorRenderedComponent
{
	UPROPERTY()
	bool bAlwaysShowInEditor = true;

	default SetHiddenInGame(false);

	AIslandSplineFollowingPerchDroidTacticalWaypoint Waypoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Waypoint = Cast<AIslandSplineFollowingPerchDroidTacticalWaypoint>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
#if EDITOR
		if(!bAlwaysShowInEditor)
			return;

		Waypoint = Cast<AIslandSplineFollowingPerchDroidTacticalWaypoint>(Owner);

		
		SetActorHitProxy();
		DrawWireSphere(WorldLocation, 40 , FLinearColor::Green, 5);
		ClearHitProxy();
		TListedActors<AIslandSplineFollowingPerchDroidTacticalWaypoint> Waypoints;
		for (int i = 0; i < Waypoints.Num()-1; i++)
		{
			if (Waypoints[i] != Waypoint)
				continue;

			for (int j = i+1; j < Waypoints.Num(); j++)
			{
				if (Waypoints[j] == Waypoint)
					continue;

				if (Waypoints[i].ActorLocation.Distance(Waypoints[j].ActorLocation) < 1000) // Temp
					DrawLine(Waypoints[i].ActorLocation, Waypoints[j].ActorLocation);
			}
		}
#endif
	}
	
};