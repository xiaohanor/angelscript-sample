namespace DarkMass
{
	namespace Tags
	{
		const FName DarkMass = n"DarkMass";
		const FName DarkMassAim = n"DarkMassAim";
		const FName DarkMassSpawn = n"DarkMassSpawn";
		const FName DarkMassPlacement = n"DarkMassPlacement";
		const FName DarkMassMovement = n"DarkMassMovement";
		const FName DarkMassGrab = n"DarkMassGrab";
	}

	const float AimRange = 3500.0;
	const float GrabRange = 1500.0;
	const float AccelerationSpeed = 3500.0;
	const float MaximumSpeed = 2000.0;
	const float Drag = 5.0;
	
	// How many simultaneous grabs we can have.
	const int MaxGrabs = 6;

	// Whether we can only grab one target component per actor.
	const bool bSingleActorGrab = true;

	// Whether we can grab components from the actor we're placed on.
	const bool bCanGrabSurface = false;

	// Whether we only move while the player is holding down the primary button.
	const bool bHoldToMove = false;
}