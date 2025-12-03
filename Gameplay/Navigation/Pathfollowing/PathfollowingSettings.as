class UPathfollowingSettings : UHazeComposableSettings
{
	// If true, we do not try to use pathfinding when moving, but always move in straight line. If false, we pathfind normally.
    UPROPERTY(Category = "Pathfinding")
	bool bIgnorePathfinding = false;

	// If destination has moved this much we will consider finding a new path.
    UPROPERTY(Category = "Pathfinding")
	float UpdatePathDistance = 100.0;

	// How close we need to be to destination before we stop.
    UPROPERTY(Category = "Pathfinding")
	float AtDestinationRange = 40.0;

	// How close we need to be to an intermediate path node before moving on to the next.
    UPROPERTY(Category = "Pathfinding")
	float AtWaypointRange = 20.0;

	// If destination is this far outside navmesh, we will be more careful when following path
    UPROPERTY(Category = "Pathfinding")
	float OutsideNavmeshEndRange = 20.0;

	// If we start this far outside navmesh, we will be more careful when following path
    UPROPERTY(Category = "Pathfinding")
	float OutsideNavmeshStartRange = 100.0;

	// How far outside navmesh can start/destination be for us to even try pathfinding?
    UPROPERTY(Category = "Pathfinding")
	float NavmeshMaxProjectionRange = 600.0;
}
