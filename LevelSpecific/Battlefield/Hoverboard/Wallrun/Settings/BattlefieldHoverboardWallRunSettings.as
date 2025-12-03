class UBattlefieldHoverboardWallRunSettings : UHazeComposableSettings
{
	// The camera angle from the wall normal required for a wall run
	UPROPERTY()
	float RequiredCameraAngle = 27.5;

	// Input angle from the wall normal required for a wall run
	UPROPERTY()
	float RequiredInputAngle = 37.5;

	// Minimum and Maximum entry speed for standard entry
	UPROPERTY()
	float MinimumSpeed = 2100.0;

	UPROPERTY()
	float MaximumSpeed = 2350.0;

	UPROPERTY()
	float HorizontalBrakingDeceleration = 400.0;

	UPROPERTY()
	float GravityStrength = 575.0;
	
	UPROPERTY()
	float LedgeGrabTargetSpeed = 600.0;

	UPROPERTY()
	float LedgeGrabTargetSpeedInterpSpeed = 2.5;

	UPROPERTY()
	float ActivationWeight = 1.0;

	UPROPERTY()
	EPlayerWallRunJumpOverride JumpOverride = EPlayerWallRunJumpOverride::None;

	const float FacingRotationInterpSpeed = 220.0;

	// Radius of the trace towards the wall. Trace distance will be adjusted to compenstate for radius changes
	const float WallTraceSphereRadius = 25.0;	

	// If you don't override enter velocity, this is the default
	const float NonOverrideAngle = 15.0;
	const float NonOverrideSpeed = 1000.0;

	// If a trace of this distance hits, you will do the dash instead of a jump
	const float DashTraceDistance = 800.0;

	//** TurnAroundSettings **
	//
	float TurnaroundSlowDownDuration = 0.8;

	//
	float TurnaroundSpeedUpDuration = 0.6;
}