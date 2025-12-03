class UIslandDroidZiplinePlayerSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Settings")
	float ThrowGrappleDuration = 0.2;

	UPROPERTY(Category = "Settings")
	float JumpToDroidDuration = 1;

	UPROPERTY(Category = "Settings")
	FVector CapsuleRelativeOffset = FVector(0.0, 0.0, -25.0);

	UPROPERTY(Category = "Settings")
	float ZiplineSidewaysInterpSpeed = 3.0;
}