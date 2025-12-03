class UDentistSplitToothAISettings : UHazeComposableSettings
{
	// How long to give input in the same direction
	UPROPERTY(Category = "Input")
	FHazeRange InputDuration = FHazeRange(0.2, 1.0);
	// Lower idle input means smaller jumps and less tilting
	UPROPERTY(Category = "Input")
	float MaxIdleInput = 0.5;
	UPROPERTY(Category = "Input")
	float InputAccelerateDuration = 0.5;

	UPROPERTY(Category = "Bobbing")
	FHazeRange BobSpeed = FHazeRange(50, 1000);
	UPROPERTY(Category = "Bobbing")
	float BobAngle = Math::DegreesToRadians(10);
	UPROPERTY(Category = "Bobbing")
	float BobFrequency = 20;

	UPROPERTY(Category = "Startled")
	float StartleDistance = 1500;

	UPROPERTY(Category = "Startled|Turn Around")
	float StartledTurnAroundDuration = 0.1;

	UPROPERTY(Category = "Startled|Jump")
	float StartledJumpDuration = 0.6;
	UPROPERTY(Category = "Startled|Jump")
	FRuntimeFloatCurve StartledJumpHeightAlphaCurve;
	UPROPERTY(Category = "Startled|Jump")
	float StartledJumpHeight = 100;
	UPROPERTY(Category = "Startled|Jump")
	FRuntimeFloatCurve StartledJumpRollAlphaCurve;
	UPROPERTY(Category = "Startled|Jump")
	float StartledJumpRollAngleDegrees = 15;

	UPROPERTY(Category = "Startled|Jump")
	FRuntimeFloatCurve StartledJumpEyeBoundaryRadiusMultiplierCurve;
	UPROPERTY(Category = "Startled|Jump")
	FRuntimeFloatCurve StartledJumpEyePupilPercentageMultiplierCurve;
};