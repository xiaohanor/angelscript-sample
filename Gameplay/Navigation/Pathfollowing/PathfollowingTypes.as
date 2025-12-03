delegate void FOnPathfollowingMoveToDone(AActor MovingActor, FVector Destination, UObject Instigator, EPathfollowingMoveToStatus Result);

enum EPathfollowingMoveToStatus
{
	None,				// No active MoveTo
	Pathfinding,		// This is currently active MoveTo, but we are waiting for pathfinding to complete or resources to become available.
	Moving,				// We're currently ready to move towards destination
	Queued,				// There are other, higher prio MoveTos ongoing that take precedence.
	AtDestination,		// MoveTo reached destination (within settings AtDestinationRange)
	AtFarAsWeCanGo,		// MoveTo reached path end, but actual destination is outside nav mesh.
	Stopped,			// MoveTo was stopped manually
	CouldNotFindStart,	// No pathfinding possible from our current location
	CouldNotFindEnd,	// No pathfinding possible to given destination
	CouldNotFindPath,	// Path to destination is blocked within navmesh
}

enum EPathfollowingPriority
{
	Lowest,
	Low,
	Medium,
	High,
	Highest,
}

enum EBasicPathfindingResult
{
	AccuratePath,
	InaccuratePath,
	BadStart,
	BadDestination,
	NoPath,
}

