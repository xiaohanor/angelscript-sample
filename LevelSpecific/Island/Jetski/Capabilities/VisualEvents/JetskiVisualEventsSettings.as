namespace Jetski::VisualEvents
{
	// If we are slightly above the water, this can help to keep us in the water (visually)
	const float ExtraWaterDistance = 40;

	// Wait this long after exiting water to actually exit
	const float ExitWaterDelay = 0.1;

	// If we are this far above the water, skip the delay to prevent jumping away from the surface and still getting the vfx
	const float IgnoreExitWaterDelayDistance = 10;
}