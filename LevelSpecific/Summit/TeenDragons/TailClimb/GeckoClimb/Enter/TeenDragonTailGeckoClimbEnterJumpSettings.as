class UTeenDragonTailGeckoClimbEnterJumpSettings : UHazeComposableSettings
{
	UPROPERTY()
	TSubclassOf<UTeenDragonGeckoClimbEnterWidget> JumpEnterWidgetClass;

	// How high you have to go on the wall aditionally to the dragons height
	UPROPERTY()
	float MinActivationJumpHeight = 400;

	// How high on the wall you can jump to
	// Based on the height of the dragon before activation
	UPROPERTY()
	float MaxActivationJumpHeight = 1000;

	// How far away you can jump to the wall
	UPROPERTY()
	float MaxActivationJumpLength = 3250;

	// How fast the activation jump is
	UPROPERTY()
	float ActivationJumpSpeed = 2000;

	// How the dragon moves over the time of the jump and the space the jump covers
	UPROPERTY()
	FRuntimeFloatCurve DefaultJumpSpeedCurve;
	default DefaultJumpSpeedCurve.AddDefaultKey(0, 0);
	default DefaultJumpSpeedCurve.AddDefaultKey(1, 1.0);
}