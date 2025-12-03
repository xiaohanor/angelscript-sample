class UPlayerAirMotionSettings : UHazeComposableSettings
{
	//Max velocity used to calculate anim data for launch
	const float ANIM_LAUNCH_MAX_HORIZONTAL_VEL = 2500;

	// Target horizontal speed
	UPROPERTY()
	float HorizontalMoveSpeed = 600.0;

	// Interp speed of your velocity (units per second)
	UPROPERTY()
	float HorizontalVelocityInterpSpeed = 1500.0;

	UPROPERTY()
	float AirControlMultiplier = 1;

	// Speeds above HorizontalMoveSpeed but below this will not apply drag
	UPROPERTY()
	float MaximumHorizontalMoveSpeedBeforeDrag = 600.0;

	// Linear drag on the overspeed if we enter air motion with higher velocity than our normal movement
	UPROPERTY()
	float DragOfExtraHorizontalVelocity = 250.0;
	
	// At this speed and below, the player will have 100% turning rate
	UPROPERTY()
	float MaximumTurnRateFallingSpeed = 1200.0;

	// The speed at which the player will have minimum turn rate (lerped between max as the player increases falling speed)
	UPROPERTY()
	float MinimumTurnRateFallingSpeed = 1800.0;

	// Rotation speed of the player towards your input
	UPROPERTY()
	float MaximumTurnRate = 2.5;
	UPROPERTY()
	float MinimumTurnRate = 1.0;

	//Rotation speed of player towards input during ApexDive
	const float ApexDiveTurnRate = 1.5;

	//Required horizontal speed for a highspeed landing to trigger
	const float HighspeedLandingHorizontalThreshhold = 1250;
}