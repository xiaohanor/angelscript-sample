namespace TeenDragonChaseRollingSettings
{
	/** The base speed forwards
	 * (Further regulated by rubberbanding)*/
	const float BaseSpeed = 2000;

	/** The most you can turn away from the spline */
	const FRotator MaxInputRotation(0, 60, 0);

	/** How fast it turns towards the input rotation */
	const float TurningAccelerationDuration = 1.0;

	/** The maximum rubberbanding speed allowed
	 * (can be positive and negative depending on if you are ahead or behind)
	 * (reached at the "DistanceForMaxRubberBandingSpeed") */
	const float MaxRubberBandingSpeed = 1000.0;

	/** How far away from the other player on the spline is allowed before reaching the maximum rubberbanding speed */
	const float DistanceForMaxRubberBandingSpeed = 2000.0;

	/** How far back behind the other player the respawn happens */
	const float RespawnBehindDistance = 2000.0;
}