namespace TeenDragonTailGeckoClimbLedgeGrabSettings
{
	// Compared to the dragon's capsule position, how far forward to trace for a ledge
	const float LedgeGrabMaxDistance = 200.0;

	// How many units from the edge the dragons final position should be
	const float LedgeGrabFinalPositionClearance = 130.0;

	const float LedgeGrabDuration = 0.6;

	const float RotationDuration = 0.4;

	// How long the dragon will freeze in place before actually starting the ledge grab (so the animation looks nice)
	const float AnticipationDelay = 0.0;

	// If false, will play the standard teen dragon camera lag/shake when landing, true will block
	const bool bBlockLandingEffectsAfterLedgeGrab = true;
}