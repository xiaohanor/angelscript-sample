class UIslandDroidZiplineSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Settings")
	float PatrolSpeed = 300.0;

	UPROPERTY(Category = "Settings")
	float PatrolToZiplineAcceleration = 1000.0;

	UPROPERTY(Category = "Settings")
	FRotator AttachShakePeakRotation = FRotator(20.0, 0.0, 0.0);

	UPROPERTY(Category = "Settings")
	float AttachShakeMaxRandomRoll = 10.0;
	
	UPROPERTY(Category = "Settings")
	float AttachShakePeakDownardsDistance = 100.0;

	UPROPERTY(Category = "Settings")
	float AttachShakeDuration = 0.2;

	UPROPERTY(Category = "Settings")
	float AttachShakeBackLerpDuration = 0.8;

	UPROPERTY(Category = "Settings")
	float ZiplineSpeed = 2400.0;

	UPROPERTY(Category = "Settings")
	float ZiplineSidewaysSpeed = 800.0;

	UPROPERTY(Category = "Settings")
	float SplineRotationInterpSpeed = 5.0;

	UPROPERTY(Category = "Settings")
	float ZiplineSidewaysRollDegrees = 15.0;
}