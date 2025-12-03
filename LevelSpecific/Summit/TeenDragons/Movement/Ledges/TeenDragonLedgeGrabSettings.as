namespace TeenDragonLedgeGrabSettings
{
	// How far in front of the dragon to trace for a wall
	const float WallMaxDistance = 100.0;

	// Compared to the dragon's capsule position, how far up to allow ledge grabbing
	const float LedgeGrabMaxHeight = 200.0;

	// How many units from the edge the dragons final position should be
	const float LedgeGrabFinalPositionClearance = 10.0;

	const float LedgeGrabDuration = 0.53;

	const float LedgeGrabTurnDuration = 0.2;

	// The Wall's pitch limits (negative is leaning towards, positive backwards)
	const float WallPitchMinimum = -10.0;
	const float WallPitchMaximum = 15.0;

	// How long the dragon will freeze in place before actually starting the ledge grab (so the animation looks nice)
	const float AnticipationDelay = 0.0;

	// If the dragon should keep its horizontal velocity after the ledge grab
	const bool bInheritVelocityAfterLedgeGrab = true;

	// If false, will play the standard teen dragon camera lag/shake when landing, true will block
	const bool bBlockLandingEffectsAfterLedgeGrab = true;
}