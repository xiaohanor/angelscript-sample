class UMagnetDroneAttractionSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Attraction")
	float AttractionStartVerticalImpulse = 0;

	// If no magnetic target was found, but the player is currently on a magnetic surface, should we attach?
	UPROPERTY(Category = "Attraction")
	bool bAttachToGroundIfNoTargetFound = true;

	UPROPERTY(Category = "Attraction")
	float AttractionFailMaxSpeed = 400;

	UPROPERTY(Category = "Attraction")
	float InputBuffer = 0.2;

	UPROPERTY(Category = "Attraction")
	float StopInputWhenGroundedBufferTime = 0.1;

	/**
	 * To prevent spamming, don't allow attraction within this interval from last time.
	 */
	UPROPERTY(Category = "Attraction")
	float MinimumAttractionInterval = 0.4;

	// If we are currently not targeting anything, and not on a magnetic surface, but there is a magnetic surface close to us, should we attract towards it?
	UPROPERTY(Category = "Attraction|Closest Surface")
	bool bAttachToClosestSurfaceIfNoTargetAndNoGround = true;

	UPROPERTY(Category = "Attraction|Closest Surface")
	float ClosestSurfaceOverlapRadius = 200;

	// How much of the player velocity that should be injected into the attraction preview.
	UPROPERTY(Category = "Attraction|Preview")
	float PreviewStartVelocityMultiplier = 0.5;

	UPROPERTY(Category = "Attraction|Preview")
	float PreviewStartVelocityAccelerateDuration = 1.0;
}