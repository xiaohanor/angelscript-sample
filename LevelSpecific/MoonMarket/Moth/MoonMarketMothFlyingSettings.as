class UMoonMarketMothFlyingSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Flying Settings")
	FHazePlaySlotAnimationParams SlotAnimParams;
	
	UPROPERTY(Category = "Flying Settings")
	UHazeCameraSpringArmSettingsDataAsset CamSettings;
	
	UPROPERTY(Category = "Flying Settings")
	float FlySpeed = 1900;

	UPROPERTY(Category = "Flying Settings")
	float RideDuration = 10;

	UPROPERTY(Category = "Flying Settings")
	float LiftDuration = 2;

	UPROPERTY(Category = "Flying Settings")
	float LiftSpeed = 400;

	UPROPERTY(Category = "Flying Settings")
	FRuntimeFloatCurve LiftSpeedCurve;

	UPROPERTY(Category = "Flying Settings")
	FRuntimeFloatCurve FlapSpeedCurve;

	UPROPERTY(Category = "Flying Settings")
	float FlapFrequency = 1.3;

	UPROPERTY(Category = "Flying Settings")
	float VerticalFlapDistance = 100;

	UPROPERTY(Category = "Flying Settings")
	float HorizontalFlapDistance = 0;
	

	UPROPERTY(Category = "Free Steering Settings")
	float MaxRoll = 180;

	UPROPERTY(Category = "Free Steering Settings")
	float MaxPitch = 60;

	UPROPERTY(Category = "Spline Steering Settings")
	float PatrolSpeed = 300.0;

	UPROPERTY(Category = "Spline Steering Settings")
	float Acceleration = 1000.0;

	UPROPERTY(Category = "Spline Steering Settings")
	FRotator AttachShakePeakRotation = FRotator(20.0, 0.0, 0.0);

	UPROPERTY(Category = "Spline Steering Settings")
	float AttachShakeMaxRandomRoll = 10.0;
	
	UPROPERTY(Category = "Spline Steering Settings")
	float AttachShakePeakDownardsDistance = 100.0;

	UPROPERTY(Category = "Spline Steering Settings")
	float AttachShakeDuration = 0.2;

	UPROPERTY(Category = "Spline Steering Settings")
	float AttachShakeBackLerpDuration = 0.8;

	UPROPERTY(Category = "Spline Steering Settings")
	float SidewaysSpeed = 800.0;

	UPROPERTY(Category = "Spline Steering Settings")
	float SidewaysInterpSpeed = 1200.0;

	UPROPERTY(Category = "Spline Steering Settings")
	float SidewaysAccelerationDuration = 1.0;

	UPROPERTY(Category = "Spline Steering Settings")
	float SplineRotationInterpSpeed = 5.0;

	UPROPERTY(Category = "Spline Steering Settings")
	float SidewaysRollDegrees = 15.0;

	UPROPERTY(Category = "Spline Steering Settings")
	FRuntimeFloatCurve SidewaysRotationCurve;


	UPROPERTY(Category = "Idle Settings")
	float IdleBobSpeed = 2.5;

	UPROPERTY(Category = "Idle Settings")
	float IdleBobStrength = 60;
}