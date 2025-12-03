class UPlayerSkydiveSettings : UHazeComposableSettings
{
	/** Movement **/

	/* [AL]
	 * These default values currently match the airmotion settings to facilitate going between them in general gameplay
	 * Override these for more control in scenario skydives
	 */

	// Target horizontal speed
	UPROPERTY()
	float HorizontalMoveSpeed = 600;

	// Interp speed of your velocity (units per second)
	UPROPERTY()
	float HorizontalVelocityInterpSpeed = 1500;

	// Speeds above HorizontalMoveSpeed but below this will not apply drag
	UPROPERTY()
	float MaximumHorizontalMoveSpeedBeforeDrag = 600;

	// Linear drag on the overspeed if we enter Skydive with higher velocity than our normal movement
	UPROPERTY()
	float DragOfExtraHorizontalVelocity = 250;

	// How fast we deccelerate our horizontal velocity when not giving input
	float HorizontalDeccelerationSpeed = 300;

	//Overrides the normal Player Terminal Velocity
	UPROPERTY()
	float TerminalVelocity = 2500;

	//Overrides the normal player gravity acceleration
	UPROPERTY()
	float GravityAmount = 2385;

	// At this speed and below, the player will have 100% turning rate
	UPROPERTY()
	float MaximumTurnRateFallingSpeed = 1200;

	// The speed at which the player will have minimum turn rate (lerped between max as the player increases falling speed)
	UPROPERTY()
	float MinimumTurnRateFallingSpeed = 1800;

	// Rotation speed of the player towards your input
	UPROPERTY()
	float MaximumTurnRate = 2.5;
	UPROPERTY()
	float MinimumTurnRate = 1.0;

	UPROPERTY(Category = "Rubber Banding")
	bool bEnableRubberbanding = false;

	// Minimum distance between players before we start rubberbanding
	UPROPERTY(Category = "Rubber Banding")
	float RubberBandMinDistance = 250.0;

	// Maximum distance between players after which we reach full rubber band modification
	UPROPERTY(Category = "Rubber Banding")
	float RubberBandMaxDistance = 2500.0;

	// Maximum slowdown of the player in front, reached when the max distance is reached
	UPROPERTY(Category = "Rubber Banding")
	float RubberBandMaxSlowdown = 0.75;

	UPROPERTY(Category = "Rubber Banding")
	float RubberBandDeccelerationSpeed = 500;

	// Maximum speedup of the player in rear, reached when the max distance is reached
	UPROPERTY(Category = "Rubber Banding")
	float RubberBandMaxSpeedUp = 1.75;

	UPROPERTY(Category = "Rubber Banding")
	float RubberBandAccelerationSpeed = 500;

	/** Camera **/

	UPROPERTY()
	float CameraPitchDegrees = 70;

	UPROPERTY()
	float FOV = 85;

	UPROPERTY()
	float IdealDistance = 200;

	UPROPERTY()
	float SpeedShimmerMultiplier = 0.35;

	UPROPERTY()
	float SpeedEffectPanningMultiplier = 1;

	/** Landing **/

	UPROPERTY(Category = Landing)
	bool bShouldTraceForLanding = true;

	const float LandingTracePredictionTime = 1.25;
}