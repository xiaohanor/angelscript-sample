class UAdultDragonLandingSiteSettings : UHazeComposableSettings
{
	/* This is how often you can blow the horn */
	UPROPERTY()
	float HornInteractionCooldown = 1.0;

	/* The interp speed of the dragon to rotate towards the landing point's rotation */
	UPROPERTY()
	float RotationInterpSpeed = 4.0;

	/* This is how fast the dragon will fly when entering the landing site */
	UPROPERTY()
	float EnterFlySpeed = 7500.0;

	/* How fast the speed interps from the current speed to the enter fly speed */
	UPROPERTY()
	float EnterFlySpeedInterpSpeed = 15.0;

	/* This offset will be applied to the camera's target rotation when landed at the landing site */
	UPROPERTY()
	FRotator AdditionalCameraRotationOffset;

	/* This is how fast the camera's rotation will interp to face in the rotation of the landing site */
	UPROPERTY()
	float CameraInterpSpeedWhenEntering = 1.0;

	/* From this point the dragon will land straight down (this is just after the bezier curve) */
	UPROPERTY()
	float LandingHeightOffset = 2000.0;

	/* This is how far the start point of the bezier curve is from the control point, this distance has bigger impact on smoothness as compared to the control to end distance. */
	UPROPERTY()
	float BezierStartToControlDistance = 5000.0;

	/* This is how far the control point is from the height offset point (which is the end of the bezier curve) */
	UPROPERTY()
	float BezierControlToEndDistance = 3000.0;

	/* The dragon will be completely still for this duration before applying the impulse, purely for animation reasons */
	UPROPERTY(Category="Take Off")
	float DelayBeforeTakingOff = 0.0;

	/* This impulse will be applied upwards after the delay before taking off */
	UPROPERTY(Category="Take Off")
	float TakeOffImpulse = 5000.0;

	/* The upwards impulse will decelerate with this value */
	UPROPERTY(Category="Take Off")
	float TakeOffDeceleration = 300;

	/* After this duration has passed since impulse was applied the dragon will go back to regular flying */
	UPROPERTY(Category="Take Off")
	float TakeOffDuration = 1.0;
}