namespace IslandSplineFollowingPerchDroid
{
	bool HasTacticalWaypointsInLevel()
	{
		TListedActors<AIslandSplineFollowingPerchDroidTacticalWaypoint> Waypoints;
		return Waypoints.Num() > 0;
	}
	
	// Returns a not too close Waypoint not already held by Actor and with clear sightline to target
	bool GetBestTacticalWaypoint(AHazeActor Actor, AHazeActor Target, TArray<AHazeActor> IgnoreActors, AIslandSplineFollowingPerchDroidTacticalWaypoint& OutTacticalWaypoint)
	{
		float ClosestDistSqr = BIG_NUMBER;
		float MinDistToWaypointSqr = 2000*2000; // TODO: setting
		TListedActors<AIslandSplineFollowingPerchDroidTacticalWaypoint> Waypoints;
		for (AIslandSplineFollowingPerchDroidTacticalWaypoint Waypoint : Waypoints)
		{
			float DistSqrActorToWaypoint = Actor.ActorLocation.DistSquared(Waypoint.ActorLocation);
			float DistSqrTargetToWaypoint = Target.ActorLocation.DistSquared(Waypoint.ActorLocation);
			float DistSqr = DistSqrActorToWaypoint + DistSqrTargetToWaypoint;
			if (DistSqrActorToWaypoint < MinDistToWaypointSqr)
				continue;
			
			if (DistSqr > ClosestDistSqr)
				continue;
			
			if (!Waypoint.IsAvailable(Actor))
				continue;

			if (Waypoint.IsHeldBy(Actor))
				continue;

			if (!Waypoint.IsValidHolder(Actor))
				continue;
			
			if (!Waypoint.IsWithinRange(Actor))
				continue;

			if (!Waypoint.HasTargetSightline(Actor, Target, IgnoreActors)) // clear view of target player from this waypoint?
				continue;

			if (!Waypoint.HasTargetSightline(Actor, Actor, IgnoreActors)) // clear path between Actor and this waypoint?
				continue;
			
			ClosestDistSqr = DistSqr;
			OutTacticalWaypoint = Waypoint;
		}
		return OutTacticalWaypoint != nullptr;
	}

	AIslandSplineFollowingPerchDroidTacticalWaypoint GetClosestTacticalWaypoint(AHazeActor Actor)
	{
		AIslandSplineFollowingPerchDroidTacticalWaypoint ReturnTacticalWaypoint;
		float ClosestDistSqr = BIG_NUMBER;
		TListedActors<AIslandSplineFollowingPerchDroidTacticalWaypoint> Waypoints;
		for (AIslandSplineFollowingPerchDroidTacticalWaypoint Waypoint : Waypoints)
		{
			if (Waypoint == Actor) // Ignore self
				continue;

			float DistSqr = Actor.ActorLocation.DistSquared(Waypoint.ActorLocation);
			if (DistSqr > ClosestDistSqr)
				continue;

			ClosestDistSqr = DistSqr;
			ReturnTacticalWaypoint = Waypoint;
		}
		return ReturnTacticalWaypoint;
	}

	bool GetTargetsClosestTacticalWaypoint(AHazeActor Actor, AHazeActor Target, TArray<AHazeActor> IgnoreActors, AIslandSplineFollowingPerchDroidTacticalWaypoint& OutTacticalWaypoint)
	{
		float ClosestDistSqr = BIG_NUMBER;		
		TListedActors<AIslandSplineFollowingPerchDroidTacticalWaypoint> Waypoints;
		for (AIslandSplineFollowingPerchDroidTacticalWaypoint Waypoint : Waypoints)
		{
			float DistSqr = Target.ActorLocation.DistSquared(Waypoint.ActorLocation);
			
			if (DistSqr > ClosestDistSqr)
				continue;
			
			if (!Waypoint.IsAvailable(Actor))
				continue;

			if (!Waypoint.IsValidHolder(Actor))
				continue;
			
			if (!Waypoint.HasTargetSightline(Actor, Target, IgnoreActors)) // clear view of target player from this waypoint?
				continue;

			if (!Waypoint.HasTargetSightline(Actor, Actor, IgnoreActors)) // clear path between Actor and this waypoint?
				continue;
			
			ClosestDistSqr = DistSqr;
			OutTacticalWaypoint = Waypoint;
		}
		return OutTacticalWaypoint != nullptr;
	}
	
}