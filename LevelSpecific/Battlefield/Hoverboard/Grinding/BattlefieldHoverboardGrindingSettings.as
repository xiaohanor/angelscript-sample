class UBattlefieldHoverboardGrindingSettings : UHazeComposableSettings
{
	// The minimum speed you can have while grinding
	UPROPERTY(Category = "Grinding")
	float MinGrindingSpeed = 2500;

	// The maximum speed you can have while grinding
	UPROPERTY(Category = "Grinding")
	float MaxGrindingSpeed = 3000;

	/* How fast the hoverboard rotates towards the grind splines rotation */
	UPROPERTY(Category = "Grinding")
	float RotationInterpSpeed = 10;

	// The camera settings which are active while grinding
	UPROPERTY(Category = "Camera")
	UHazeCameraSettingsDataAsset CameraSettings;

	// How long it takes to blend in the camera settings
	UPROPERTY(Category = "Camera")
	float CameraBlendTime = 1.5;

	/* How long it takes to reach the point 
	that the camera samples for rotation to look in
	(in seconds)*/
	UPROPERTY(Category = "Camera")
	float TimeToCameraLookAheadPoint = 0.5;

	UPROPERTY(Category = "Camera")
	TSubclassOf<UCameraShakeBase> GrindCameraShake;

	/* The impulse of the jump when you jump without input 
	(the Jump when you land on the grind again)*/
	UPROPERTY(Category = "Jump")
	float GrindJumpImpulse = 1500;

	/* Threshold of the angle between the relative input to the player and the grinding direction
	under which the jump will just land on the grind again, and over which will leave the grind */
	UPROPERTY(Category = "Jump Off")
	float AngleThresholdToLeaveGrindJump = 35;

	/* The Impulse of the jump off the grind 
	which is upwards*/
	UPROPERTY(Category = "Jump Off")
	float GrindLeaveJumpUpwardsImpulse = 1300;

	/* The Impulse of the jump off the grind 
	which is towards the input relative to the player*/
	UPROPERTY(Category = "Jump Off")
	float GrindLeaveJumpInputImpulse = 1100;

	/* How far away to nearest grind spline location is allowed for helping with jump to grind */
	UPROPERTY(Category = "Jump to Grind")
	float MaxDistanceToGrindForJump = 1500.0;

	/* How long the velocity is simulated to find a point for the jump to grind helper
	(in seconds) */
	UPROPERTY(Category = "Jump to Grind")
	float VelocityDurationForJumpToGrindPointSampling = 0.5;

	/* Minimum speed for jumping to grind
	For if you are standing still and trying to jump to grind */
	UPROPERTY(Category = "Jump to Grind")
	float JumpToGrindMinSpeed = 2000.0;

	/** How far away from the input the grind point can be before being discarded */
	UPROPERTY(Category = "Jump to Grind")
	float JumpToGrindAngleThreshold = 8.0;

	/* How much further ahead the grapple is placed in the direction of the players velocity */
	UPROPERTY(Category = "Grapple")
	float GrapplePointOffset = 2200;

	UPROPERTY(Category = "Grapple")
	TSubclassOf<AGrapplePoint> GrapplePointClass;

	UPROPERTY(Category = "Grapple")
	float GrappleActivationRange = 4500.0;

	UPROPERTY(Category = "Grapple")
	float GrappleAdditionalVisibleRange = 3500.0;


	// BALANCE
	UPROPERTY(Category = "Balance")
	TSubclassOf<UBattlefieldHoverboardGrindWidget> GrindWidgetClass;

	UPROPERTY(Category = "Balance")
	float InputBalanceAcceleration = 2.0;

	UPROPERTY(Category = "Balance")
	float InputBalanceMaxSpeed = 1.5;

	UPROPERTY(Category = "Balance")
	float MaxBalanceMeshRotation = 70.0;
	
	UPROPERTY(Category = "Balance")
	float BalanceFallOffSidewaysImpulseSize = 600.0;

	UPROPERTY(Category = "Balance")
	float BalanceFallOffDownwardsImpulseSize = 200.0;

	UPROPERTY(Category = "Balance")
	FVector BalanceOffsetMax = FVector(0.0, 100.0, 30.0);

	UPROPERTY(Category = "Balance")
	float SpeedSidewaysForMaximumBalanceLandImpulse = 2000.0;

	UPROPERTY(Category = "Balance")
	float MaximumBalanceLandImpulse = 0.6;

	UPROPERTY(Category = "Balance")
	float BalanceAccelerationPerDegreesLeft = 0.03;

	UPROPERTY(Category = "Balance")
	float BalanceMaxCameraTilt = 50.0;

	UPROPERTY(Category = "Balance")
	float BalanceCameraTiltDuration = 1.0;

	UPROPERTY(Category = "Suction to Grind")
	float MaxHorizontalSuctionDistance = 1200.0;
	
	UPROPERTY(Category = "Suction to Grind")
	float MaxVerticalSuctionDistance = 240;

	UPROPERTY(Category = "Suction to Grind")
	FHazeRange SuctionSpeed = FHazeRange(0, 300.0);

	UPROPERTY(Category = "Suction to Grind")
	FHazeRange SuctionAcceleration = FHazeRange(0, 1.4);

	UPROPERTY(Category = "Suction to Grind")
	float SuctionToGrindOverrideDistance = 250.0;

	UPROPERTY(Category = "Suction to Grind")
	float SuctionToGrindLandLocationVelocityEstimationDuration = 0.5;
}