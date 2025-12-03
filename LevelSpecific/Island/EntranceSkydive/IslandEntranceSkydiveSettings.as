class UIslandEntranceSkydiveSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Movement|Barrel Roll")
	float BarrelRollSpeed = 900.0;

	UPROPERTY(Category = "Movement|Barrel Roll")
	FRuntimeFloatCurve BarrelRollSpeedCurve;
	default BarrelRollSpeedCurve.AddDefaultKey(0.0, 1.0);
	default BarrelRollSpeedCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(Category = "Movement|Barrel Roll")
	float BarrelRollDuration = 0.8;

	UPROPERTY(Category = "Movement|Barrel Roll")
	float BarrelRollAnimationDuration = 0.8;

	UPROPERTY(Category = "Movement|Barrel Roll")
	float BarrelRollCooldown = 0.5;

	UPROPERTY(Category = "Movement|Barrel Roll")
	float BarrelRollVelocityInterpSpeed = 10.0;

	// Target horizontal speed
	UPROPERTY(Category = "Movement")
	float HorizontalMoveSpeed = 600;

	UPROPERTY(Category = "Movement")
	float DragFactor = 2.0;

	UPROPERTY(Category = "Movement")
	float TerminalVelocity = 2500;

	UPROPERTY(Category = "Movement")
	float TerminalVelocityAccelerationDuration = 0.5;

	UPROPERTY(Category = "Movement")
	float GravityAmount = 2385;

	// The speed at which the player will have minimum turn rate (lerped between max as the player increases falling speed)
	// UPROPERTY(Category = "Movement|Turn Rate")
	// float MinimumTurnRateFallingSpeed = 1800;

	// // At this speed and below, the player will have 100% turning rate
	// UPROPERTY(Category = "Movement|Turn Rate")
	// float MaximumTurnRateFallingSpeed = 1200;

	// // Minimum rotation speed of the player towards your input
	// UPROPERTY(Category = "Movement|Turn Rate")
	// float MinimumTurnRate = 1.0;

	// // Maximum rotation speed of the player towards your input
	// UPROPERTY(Category = "Movement|Turn Rate")
	// float MaximumTurnRate = 2.5;

	UPROPERTY(Category = "Camera")
	float CameraPitchDegrees = 70;

	UPROPERTY(Category = "Camera")
	float FOV = 85;

	UPROPERTY(Category = "Camera")
	float IdealDistance = 200;

	UPROPERTY(Category = "Camera")
	float SpeedShimmerMultiplier = 0.6;

	UPROPERTY(Category = "Camera")
	float SpeedEffectPanningMultiplier = 0.6;

	UPROPERTY(Category = "Camera")
	bool bSyncRelativeToFallHeight = false;
}