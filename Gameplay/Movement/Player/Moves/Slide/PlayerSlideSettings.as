class UPlayerSlideSettings : UHazeComposableSettings
{
	/**
	 * Minimum speed that we can slide at.
	 * For forced slides, speed will never drop below this.
	 * For temporary slides, if we go below this speed we will stop sliding.
	 */
	UPROPERTY()
	float SlideMinimumSpeed = 500.0;

	/**
	 * Maximum speed that we can slide at.
	 * We will never exceed this speed when going downhill.
	 */
	UPROPERTY()
	float SlideMaximumSpeed = 1500.0;

	/**
	 * When not going downhill or uphill, stabilize our sliding speed at this target.
	 * NB: Temporary slides always have a target speed of 0, and will slow down on even ground.
	 */
	UPROPERTY()
	float SlideTargetSpeed = 750.0;

	/**
	 * How much speed we lose or gain to reach the target speed every second.
	 */
	UPROPERTY()
	float TargetInterpAcceleration = 1000.0;

	/**
	 * Velocity gained per second per angle of downward slope.
	 */
	UPROPERTY()
	float DownhillAcceleration = 80.0;

	/**
	 * Velocity lost per second per angle of upward slope.
	 */
	UPROPERTY()
	float UphillDeceleration = 20.0;

	/**
	 * How much speed we lose per second while in a temporary slide.
	 */
	UPROPERTY()
	float TemporarySlideSlowdownDeceleration = 1000.0;

	/**
	 * How fast we move left and right compared to the slide direction.
	 */
	UPROPERTY()
	float SidewaysSpeed = 500.0;

	/**
	 * How fast we accelerate left and right compared to the slide direction
	 */
	UPROPERTY()
	float SidewaysAcceleration = 1500.0;

	/**
	 * If constraining the width of the spline, what percentage of the spline width to use to slow down in.
	 */
	UPROPERTY()
	float SidewaysConstrainedWidthPercentage = 0.3;

	/**
	 * How fast our sideways speed decelerates to 0 when not holding input at all.
	 */
	UPROPERTY()
	float SidewaysNoInputDeceleration = 300.0;

	/**
	 * How much to go sideways per degree of sideways tilt on the slope.
	 */
	UPROPERTY()
	float TiltSidewaysSpeedPerDegree = 30.0;

	/**
	 * Maximum sideways speed to gain from tilt.
	 */
	UPROPERTY()
	float TiltSidewaysSpeedMaximum = 1000.0;

	// How fast the character rotates facing while sliding
	UPROPERTY()
	float FacingRotationSpeed = 1.0;

	// Capsule half height when sliding
	UPROPERTY()
	float CapsuleHalfHeight = 38.0;

	// How far extra we want to sweep when finding the ground. Higher values means we stick more to the ground.
	UPROPERTY()
	float GroundStickynessDistance = 10;

	//How many degrees above the slide surface the assist will put the camera pitch wise
	UPROPERTY(Category = "Camera Assist")
	float AdditionalCameraPitchAssist = 15.0;

	//How many degrees above the slide surface we clamp the pitch of the camera
	UPROPERTY(Category = "Camera Assist")
	float AdditionalCameraPitchClampAngle = -10.0;

	//How long we wait for when camera input stops before activating camera assist
	UPROPERTY(Category = "Camera Assist")
	float ASSIST_INPUT_COOLDOWN = 0.66;

	//How long does it take to accelerate the camera rotation back to our assist direction
	UPROPERTY(Category = "Camera Assist")
	float ROTATION_ACCELERATION_DURATION = 3;

	// Whether to keep the slide velocity while jumping in air above the slide
	UPROPERTY(Category = "Air Motion")
	bool bKeepSlideVelocityInAir = true;

	/**
	 * Whether to slow down to the slide's normal target speed while in air.
	 * If false, we keep all of our existing slide momentum in the air above the slide.
	 */
	UPROPERTY(Category = "Air Motion")
	bool bSlowdownToTargetSpeedInAir = false;

	// Multiplier to the target speed while the player is in the air
	UPROPERTY(Category = "Air Motion")
	float AirMotionTargetSpeedMultiplier = 1.0;

	/**
	 * Whether to use the spline's sideways movement speed when the player is in air,
	 * overriding the player's normal air velocity.
	 */
	UPROPERTY(Category = "Air Motion")
	bool bUseSidewaysMovementSpeedInAir = false;

	// Multiplier to the slide's sideways speed while the player is in air
	UPROPERTY(Category = "Air Motion")
	float AirMotionSildewaysMovementSpeedMultiplier = 1.0;

	// Maximum angle from the slide's forward direction to constrain air dashes in during slide
	UPROPERTY(Category = "Air Motion")
	float AirDashMaximumForwardDeviationAngle = 80.0;

	// Whether to rubber band players' slide speed based on their distance
	UPROPERTY(Category = "Rubber Banding")
	bool bEnableRubberBanding = false;

	// Minimum distance between players before we start rubberbanding
	UPROPERTY(Category = "Rubber Banding")
	float RubberBandMinDistance = 1000.0;

	// Maximum distance between players after which we reach full rubber band modification
	UPROPERTY(Category = "Rubber Banding")
	float RubberBandMaxDistance = 3000.0;

	// Maximum slowdown of the player in front, reached when the max distance is reached
	UPROPERTY(Category = "Rubber Banding")
	float RubberBandMaxSlowdown = 0.5;

	// Maximum speedup of the player in rear, reached when the max distance is reached
	UPROPERTY(Category = "Rubber Banding")
	float RubberBandMaxSpeedUp = 1.5;

	// If set, the rubberbanding distances will adapt to the ping in network to compensate for crumb trail delay
	UPROPERTY(Category = "Rubber Banding")
	bool bRubberBandRemovePingFromDistance = true;

	// Whether to offset the rubberbanding so one or the other player ends up in front
	UPROPERTY(Category = "Rubber Banding")
	EPlayerSlideRubberBandOffsetType RubberBandOffset = EPlayerSlideRubberBandOffsetType::NoOffset;

	// How much to offset the rubberbanding by
	UPROPERTY(Category = "Rubber Banding")
	float RubberBandOffsetDistance = 1000.0;

	//Should we block WaterVFX from triggering and instead go by physmat as usual (SideEffect of using Audio´s water movement volumes in other levels)
	UPROPERTY(Category = "VFX")
	bool bInDesertLevel = false;
}

enum EPlayerSlideRubberBandOffsetType
{
	// No offset between the players, both players rubberband to be at roughly the same distance
	NoOffset,
	// Mio rubberbands to be in front of Zoe
	MioInFrontOfZoe,
	// Zoe rubberbands to be in front of Mio
	ZoeInFrontOfMio,
}