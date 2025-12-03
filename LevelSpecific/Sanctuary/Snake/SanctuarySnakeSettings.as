class USanctuarySnakeSettings : UHazeComposableSettings
{
	UPROPERTY()
	float Drag = 1.0;

	UPROPERTY()
	float Acceleration = 1500.0;

	UPROPERTY()
	float Gravity = 980.0;

	UPROPERTY()
	float StartLength = 3000.0;

	UPROPERTY()
	int NumSegments = 20;

	UPROPERTY()
	float PlayerDamageRadius = 150.0;

	UPROPERTY()
	float SegmentHeightOffset = -150.0;

	UPROPERTY()
	float EatDistance = 300.0;
};