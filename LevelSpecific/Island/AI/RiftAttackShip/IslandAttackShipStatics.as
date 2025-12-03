namespace IslandAttackShip
{
	bool HasWaypointsInLevel()
	{
		TListedActors<AIslandAttackShipScenepointActor> Waypoints;
		return Waypoints.Num() > 0;
	}
		
	bool GetNextWaypoint(AHazeActor Actor, TArray<AHazeActor> IgnoreActors, AIslandAttackShipScenepointActor CurrentWaypoint,AIslandAttackShipScenepointActor& OutWaypoint)
	{
		float ClosestDistSqr = BIG_NUMBER;		
		TListedActors<AIslandAttackShipScenepointActor> Waypoints;
		for (AIslandAttackShipScenepointActor Waypoint : Waypoints)
		{
			if (Waypoint == CurrentWaypoint)
				continue;

			float DistSqr = Actor.ActorLocation.DistSquared(Waypoint.ActorLocation);
			
			if (DistSqr > ClosestDistSqr)
				continue;			
			
			ClosestDistSqr = DistSqr;
			OutWaypoint = Waypoint;
		}
		return OutWaypoint != nullptr;
	}
	
	bool GetClosestCrashpoint(AHazeActor Actor, AIslandAttackShipCrashpointActor& OutCrashpoint)
	{
		float ClosestDistSqr = BIG_NUMBER;		
		TListedActors<AIslandAttackShipCrashpointActor> Crashpoints;
		for (AIslandAttackShipCrashpointActor Crashpoint : Crashpoints)
		{			
			float DistSqr = Actor.ActorLocation.DistSquared(Crashpoint.ActorLocation);
			
			if (DistSqr > ClosestDistSqr)
				continue;			
			
			ClosestDistSqr = DistSqr;
			OutCrashpoint = Crashpoint;
		}
		return OutCrashpoint != nullptr;
	}

	bool GetClosestTriggerCrashpoint(AHazeActor Actor, AIslandAttackShipCrashpointActor& OutCrashpoint)
	{
		float ClosestDistSqr = BIG_NUMBER;
		TListedActors<AIslandAttackShipCrashpointActor> Crashpoints;
		for (AIslandAttackShipCrashpointActor Crashpoint : Crashpoints)
		{
			if (Crashpoint.bIsUsed)
				continue;

			if (!Crashpoint.bIsTriggerCrashpoint)
				continue;

			float DistSqr = Actor.ActorLocation.DistSquared(Crashpoint.ActorLocation);
			
			if (DistSqr > ClosestDistSqr)
				continue;
			
			ClosestDistSqr = DistSqr;
			OutCrashpoint = Crashpoint;
		}
		return OutCrashpoint != nullptr;
	}

	bool GetClosestNonTriggerCrashpoint(AHazeActor Actor, AIslandAttackShipCrashpointActor& OutCrashpoint)
	{
		float ClosestDistSqr = BIG_NUMBER;
		TListedActors<AIslandAttackShipCrashpointActor> Crashpoints;
		for (AIslandAttackShipCrashpointActor Crashpoint : Crashpoints)
		{
			if (Crashpoint.bIsUsed)
				continue;

			if (Crashpoint.bIsTriggerCrashpoint)
				continue;

			float DistSqr = Actor.ActorLocation.DistSquared(Crashpoint.ActorLocation);
			
			if (DistSqr > ClosestDistSqr)
				continue;
			
			ClosestDistSqr = DistSqr;
			OutCrashpoint = Crashpoint;
		}
		return OutCrashpoint != nullptr;
	}


	bool GetClosestManager(AHazeActor Actor, AIslandAttackShipManagerActor& OutManager)
	{
		float ClosestDistSqr = BIG_NUMBER;
		TListedActors<AIslandAttackShipManagerActor> Crashpoints;
		for (AIslandAttackShipManagerActor Crashpoint : Crashpoints)
		{			
			float DistSqr = Actor.ActorLocation.DistSquared(Crashpoint.ActorLocation);
			
			if (DistSqr > ClosestDistSqr)
				continue;			
			
			ClosestDistSqr = DistSqr;
			OutManager = Crashpoint;
		}
		return OutManager != nullptr;
	}
}