class UWallclimbingPathfollowingSettings : UHazeComposableSettings
{
	// We reduce actual height difference by this much when checking if we've reached path nodes 
    UPROPERTY(Category = "Pathfinding")
	float AtPointHeightTolerance = 100.0;

	// How far above/below navmesh can start/destination be for us to even try pathfinding?
    UPROPERTY(Category = "Pathfinding")
	float NavmeshMaxProjectionHeight = 400.0;

	// How far horizontally outside navmesh can start/destination be for us to even try pathfinding? 
    UPROPERTY(Category = "Pathfinding")
	float NavmeshMaxProjectionWidth = 20.0;

	// How fast we reach max movespeed
    UPROPERTY(Category = "Movement")
	float AccelerationDuration = 2.0;

	// How fast we change which directions are up/down 
    UPROPERTY(Category = "Movement")
	float GravityDirectionAccelerationDuration = 0.2;
}
