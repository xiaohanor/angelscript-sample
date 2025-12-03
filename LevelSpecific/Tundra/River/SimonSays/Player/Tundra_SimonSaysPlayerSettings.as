class UTundra_SimonSaysPlayerSettings : UHazeComposableSettings
{
	UPROPERTY()
	float RotationInterpSpeed = 20.0;

	/* How long it should take to jump to a platform */
	UPROPERTY()
	float PerchJumpDuration = 0.75;

	UPROPERTY()
	float PerchJumpUpHeight = 250.0;

	UPROPERTY()
	FVector DefaultForwardDirection = FVector(0.0, 1.0, 0.0);
}