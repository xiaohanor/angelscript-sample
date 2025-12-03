class UBattlefieldHoverboardGroundMovementSettings : UHazeComposableSettings
{
	/* Minimum Speed allowed for the hoverboard
	(Not including input and rubberbanding) */
	UPROPERTY(Category = "Speed")
	float MinSpeed = 3200.0;

	/** How fast you accelerate per second up to the minimum speed */
	UPROPERTY(Category = "Speed")
	float UnderSpeedAcceleration = 2000.0;

	/* Base movement speed which will be headed towards 
	when traversing on non slopy terrain */
	UPROPERTY(Category = "Speed")
	float BaseSpeed = 3600.0;

	/* Maximum Speed allowed for the hoverboard
	(Not including input and rubberbanding) */
	UPROPERTY(Category = "Speed")
	float MaxSpeed = 4300.0;

	/* How much of the gravity force is applied to gain speed in downwards slopes */
	UPROPERTY(Category = "Speed")
	float DownSlopeAccelerationMultiplier = 0.2;

	/* How much of the gravity force is applied to lose speed in upwards slopes */
	UPROPERTY(Category = "Speed")
	float UpSlopeDecelerationMultiplier = 0.1;

	/* How much faster/slower the hoverboard goes with input
	Forward left stick increases speed
	Backward left stick decreases speed
	(Added on top of normal speed)*/
	UPROPERTY(Category = "Input Speed")
	float InputSpeedMax = 0.0;

	/* How fast the input accelerates the board towards the max input speed*/
	UPROPERTY(Category = "Input Speed")
	float InputSpeedAcceleration = 1500.0;

	// How fast the wanted rotation updates with input
	UPROPERTY(Category = "Rotation")
	float WantedRotationSpeed = 50.0;

	// How fast it rotates towards the wanted rotation
	UPROPERTY(Category = "Rotation")
	float RotationDuration = 0.025;

	// How fast it rotates towards the wanted rotation during input
	UPROPERTY(Category = "Rotation")
	float RotationDurationDuringInput = 0.06;

	// Over which angle the turn speed is at max
	UPROPERTY(Category = "Rotation")
	float SlopeTurnAngleMax = 75;

	// How fast the Slope turning is
	UPROPERTY(Category = "Rotation")
	float SlopeTurnSpeed = 80;

	UPROPERTY(Category = "Animation")
	float DistanceFromGround = 100;

	/* Time Axle : Fraction of how much angle the ground is (0 is no angle 1 is SlopeTurnAngleMax) 
	Value Axle : Turn speed multiplier */
	UPROPERTY(Category = "Rotation")
	FRuntimeFloatCurve SlopeTurnCurve;
	default SlopeTurnCurve.AddDefaultKey(0, 0);
	default SlopeTurnCurve.AddDefaultKey(0.25, 0.1);
	default SlopeTurnCurve.AddDefaultKey(0.5, 0.65);
	default SlopeTurnCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> GroundCameraShake;

	UPROPERTY(Category = "Rumble")
	UForceFeedbackEffect LandingRumble;

	UPROPERTY(Category = "Rumble")
	float LandingSpeedForFullRumble = 8000.0;

	/** Time Axle 0 -> 1 : Fraction of how much speed aligned with the ground impact was had to the max
	 *  Value Axle 0 -> 1 : Rumble multiplier
	*/
	UPROPERTY(Category = "Rumble")
	FRuntimeFloatCurve LandingRumbleCurve;
	default LandingRumbleCurve.AddDefaultKey(0, 0);
	default LandingRumbleCurve.AddDefaultKey(0.4, 0);
	default LandingRumbleCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(Category = "Rumble")
	UForceFeedbackEffect WallRumble;

	UPROPERTY(Category = "Rumble")
	float WallSpeedForFullRumble = 3000.0;

	/** Time Axle 0 -> 1 : Fraction of how much speed aligned with the wall impact was had to the max
	 *  Value Axle 0 -> 1 : Rumble multiplier
	*/
	UPROPERTY(Category = "Rumble")
	FRuntimeFloatCurve WallRumbleCurve;
	default WallRumbleCurve.AddDefaultKey(0, 0);
	default WallRumbleCurve.AddDefaultKey(0.4, 0);
	default WallRumbleCurve.AddDefaultKey(1.0, 1.0);
}