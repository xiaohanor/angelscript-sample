class UAdultDragonStrafeSettings : UHazeComposableSettings
{
	// FORWARD
	/** The minimum speed you can have forwards. */
	UPROPERTY(Category = "Forward")
	float ForwardMinSpeed = 11600.0;
	// float ForwardMinSpeed = 7700.0 * 1.135;
	// float ForwardMinSpeed = 9700.0;

	/** The maximum speed you can have forwards. */
	UPROPERTY(Category = "Forward")
	float ForwardMaxSpeed = 12500.0;
	// float ForwardMaxSpeed = 8800.0 * 1.135;
	// float ForwardMaxSpeed = 11800.0;

	/** The amount of speed gained per degree per second going downwards. */
	UPROPERTY(Category = "Forward")
	// float SpeedGainedGoingDown = 20.0;
	float SpeedGainedGoingDown = 30.0;

	/** The amount of speed lost per degree per second going upwards. */
	UPROPERTY(Category = "Forward")
	// float SpeedLostGoingUp = 10.0;
	float SpeedLostGoingUp = 20.0;


	//STRAFE
	/** How much you can turn offset from the spline rotation */
	UPROPERTY(Category = "Strafe Turning")
	FRotator MaxTurningOffset(50,50, 0);

	UPROPERTY(Category = "Strafe Turning")
	float StrafeTurningDuration = 2.35;

	// How long it takes to turn back towards the spline if you have no input
	UPROPERTY(Category = "Strafe Turning")
	float StrafeTurnBackDuration = 3.0;

	// Should the movement be more loose along the spline
	UPROPERTY(Category = "Strafing FreeFly")
	bool bUseFreeFlyStrafe = false;

	// How far ahead the spline, the location we turn towards should be
	UPROPERTY(Category = "Strafing FreeFly")
	float ClosestSplinePositionForwardOffset = 2000;

	/**
	 * How far from the spline should we start ignoring input
	 * @time; the distance to the spline (0->1)
	 * @value; the input amount that should be ignore (0->1)
	 */
	UPROPERTY(Category = "Strafing FreeFly")
	FRuntimeFloatCurve IgnoreMovementDependingOnSplineDistance;
	default IgnoreMovementDependingOnSplineDistance.AddDefaultKey(0, 0);
	default IgnoreMovementDependingOnSplineDistance.AddDefaultKey(0.8, 0);
	default IgnoreMovementDependingOnSplineDistance.AddDefaultKey(1, 1);

	/**
	 * How far from the spline should we start looking at the closest spline position
	 * @time; the distance to the spline (0->1)
	 * @value; 0; don't look at the spline. 1; look only at the spline
	 */
	UPROPERTY(Category = "Strafing FreeFly")
	FRuntimeFloatCurve LookAtSplineDependingOnSplineDistance;
	default LookAtSplineDependingOnSplineDistance.AddDefaultKey(0, 0);
	default LookAtSplineDependingOnSplineDistance.AddDefaultKey(0.5, 0);
	default LookAtSplineDependingOnSplineDistance.AddDefaultKey(1.0, 1.0);

	//DASH
	UPROPERTY(Category = "Dash")
	// float DashMaxSpeed = 9000.0;
	//Doesn't need to add much more speed, camera does most of the work
	float DashMaxSpeed = 5000.0;

	UPROPERTY(Category = "Dash")
	float DashDuration = 0.7;

	UPROPERTY(Category = "Dash")
	float MinPercentAngleDeviationForSpeedMultiplier = 0.6;

	UPROPERTY(Category = "Dash")
	FRotator DashMaxTurningOffset(40,55, 0);
	
	UPROPERTY(Category = "Dash")
	FRuntimeFloatCurve DashSpeedCurve;

	/** Whether or not you should be able to redirect the dash with input during the dash */
	UPROPERTY(Category = "Dash")
	bool bRedirectDuringDash = true;

	/** How many degrees per second you can redirect the dash with input if that is enabled */
	UPROPERTY(Category = "Dash")
	float DashRedirectSpeed = 120.0;

	UPROPERTY(Category = "Dash")
	float DashCooldown = 0.4;

	
	//CAMERA BLENDS
	UPROPERTY(Category = "Camera")
	float CameraBlendInTime = 1.5;

	UPROPERTY(Category = "Camera")
	float CameraBlendOutTime = 1.8;
	
	/** How much the camera takes the rotation of the player
	 * 0 = Only follow spline
	 * 1 = Full player rotation
	 * This is based on the distance to the follow spline,
	 * so on the spline, the Min value is used
	 */
	UPROPERTY(Category = "Camera")
	FHazeRange CameraPlayerRotationFraction = FHazeRange(0.3, 1.0);

	/** How fast the camera rotates towards the players input rotation */
	UPROPERTY(Category = "Camera")
	float CameraPlayerRotationAccelerationDuration = 2.75;
}