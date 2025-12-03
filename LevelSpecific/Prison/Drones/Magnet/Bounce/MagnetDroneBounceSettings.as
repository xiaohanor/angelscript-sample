class UMagnetDroneBounceSettings : UHazeComposableSettings 
{
	UPROPERTY(Category = "Bounce")
	float BounceMinimumVerticalSpeed = -500;

	UPROPERTY(Category = "Bounce")
	float BounceRestitution = 0.435;

	/**
	 * If the angle is steeper than this, don't bounce
	 */
	UPROPERTY(Category = "Bounce")
	float BounceAngleThreshold = 20;

	UPROPERTY(Category = "Bounce")
	FRuntimeFloatCurve BounceFromHorizontalFactorOverSpeedSpline;
}