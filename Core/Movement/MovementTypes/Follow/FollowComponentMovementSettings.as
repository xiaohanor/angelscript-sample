class UFollowComponentMovementSettings : UHazeComposableSettings
{
	/**
	 * If higher than 1, we will handle depenetration issues by running multiple iterations
	 */
	UPROPERTY()
	int MaxIterations = 1;

	/**
	 * If true, we will redirect along hit surfaces to move the full amount we need to follow.
	 * If false, we instead stop at the first valid impact.
	 */
	UPROPERTY()
	bool bSlideAlongSurfaces = true;

	/**
	 * More expensive depenetration that tries to do a reverse sweep back to find the surface we are penetrating.
	 * If this fails, regular depenetration starts.
	 */
	UPROPERTY()
	bool bUseSweepBackDepenetration = false;
}