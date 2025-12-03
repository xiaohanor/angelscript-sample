namespace SpaceWalk
{
	const bool bDetachWhenPassingHookPoint = true;
	const bool bDetachWhenHittingCollision = true;
	const bool bReceiveVelocityFromHookPointMoving = true;
	const bool bCancelBackwardsVelocityWhenAttaching = false;

	const float MaximumHorizontalVelocityBeforeDrag = 1800.0;
	// original value 800.0
	const float HorizontalDragFactor = 0.2;

	const float MaximumVerticalVelocityBeforeDrag = 200.0;
	const float VerticalDragFactor = 0.2;

	const float ManueveringAcceleration = 1050.0;
	// original value 1050.0

	const float HookAttachedManeuveringAcceleration = 2000.0;
	const float HookLateralVelocityDrag = 0.2;
	const float HookLateralVelocityDragWhenForcingAutoCone = 0.01;

	// When the player is this far away from the closest hook point, kill them
	const float DistanceFromClosestHookPointToKillPlayer = 8000;

	// How far away the debris that kills the player is spawned
	const float DebrisSpawnDistanceFromPlayer = 4000;

}