namespace IslandJetpackShieldotron
{
	const float MinDistSqr2DToTarget = 1500*1500;

	bool HasTacticalWaypointsInLevel()
	{
		TListedActors<AIslandJetpackShieldotronTacticalWaypoint> Waypoints;
		return Waypoints.Num() > 0;
	}
	
	// Returns a not too close Waypoint not already held by Actor and with clear sightline to target
	bool GetBestTacticalWaypoint(AHazeActor Actor, AHazeActor Target, TArray<AHazeActor> IgnoreActors, AIslandJetpackShieldotronTacticalWaypoint& OutTacticalWaypoint, float MinDistToWaypoint = 0)
	{
		float ClosestDistSqr = BIG_NUMBER;
		float MinDistToWaypointSqr = MinDistToWaypoint*MinDistToWaypoint;
		TListedActors<AIslandJetpackShieldotronTacticalWaypoint> Waypoints;
		for (AIslandJetpackShieldotronTacticalWaypoint Waypoint : Waypoints)
		{
			float DistSqrActorToWaypoint = Actor.ActorLocation.DistSquared(Waypoint.ActorLocation);
			float DistSqrTargetToWaypoint = Target.ActorLocation.DistSquared(Waypoint.ActorLocation);
			float DistSqr = DistSqrActorToWaypoint + DistSqrTargetToWaypoint;
			if (DistSqrActorToWaypoint < MinDistToWaypointSqr)
				continue;
			
			if (DistSqr > ClosestDistSqr)
				continue;

			if (Waypoint.ActorLocation.DistSquared2D(Target.ActorLocation) < MinDistSqr2DToTarget) // do not select a waypoint right above the target
				continue;
			
			if (!Waypoint.IsAvailable())
				continue;

			if (Waypoint.IsHeldBy(Actor))
				continue;

			if (!Waypoint.IsValidHolder(Actor))
				continue;
			
			if (!Waypoint.HasTargetSightline(Actor, Target, IgnoreActors))
				continue;
			
			ClosestDistSqr = DistSqr;
			OutTacticalWaypoint = Waypoint;
		}
		return OutTacticalWaypoint != nullptr;
	}

	AIslandJetpackShieldotronTacticalWaypoint GetClosestTacticalWaypoint(AHazeActor Actor)
	{
		AIslandJetpackShieldotronTacticalWaypoint ReturnTacticalWaypoint;
		float ClosestDistSqr = BIG_NUMBER;
		TListedActors<AIslandJetpackShieldotronTacticalWaypoint> Waypoints;
		for (AIslandJetpackShieldotronTacticalWaypoint Waypoint : Waypoints)
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
	
}