namespace TeenDragonAutoGlideStrafeSettings
{
	/** The base speed forwards
	 * (Further regulated by rubberbanding)*/
	const float BaseSpeed = 2750;
	/** The most you can turn away from the spline */
	const FRotator MaxInputRotation(0, 40, 0);

	/** How fast it turns towards the input rotation */
	const float TurningAccelerationDuration = 2.5;

	/** The maximum rubberbanding speed allowed
	 * (can be positive and negative depending on if you are ahead or behind)
	 * (reached at the "DistanceForMaxRubberBandingSpeed") */
	const float MaxRubberBandingSpeed = 750.0;

	/** How far away from the other player on the spline is allowed before reaching the maximum rubberbanding speed */
	const float DistanceForMaxRubberBandingSpeed = 2000.0;

	/** How far back behind the other player the respawn happens */
	const float RespawnBehindDistance = 500.0;
}