class UMeltdownSkydiveSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Movement")
	float HorizontalMoveSpeed = 2000;

	UPROPERTY(Category = "Movement")
	float HorizontalDragFactor = 2.0;

	// How far we need to be away from the center before we start getting pulled back
	UPROPERTY(Category = "Movement")
	float FreeDistanceFromCenter = 150;

	// How far we can get away from the center at all
	UPROPERTY(Category = "Movement")
	float MaxDistanceFromCenter = 300;

	UPROPERTY(Category = "Movement")
	float BarrelRollSpeed = 3000.0;

	UPROPERTY(Category = "Movement")
	float BarrelRollDrag = 2.0;

	UPROPERTY(Category = "Movement")
	float BarrelRollDuration = 0.8;

	UPROPERTY(Category = "Movement")
	float BarrelRollCooldown = 0.5;

	UPROPERTY(Category = "Movement")
	float FallingVelocity = 9000;
}