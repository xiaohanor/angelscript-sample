class USanctuaryFlightSettings : UHazeComposableSettings
{
	UPROPERTY(Category = Movement)
	float Acceleration = 8000.0;

	UPROPERTY(Category = Movement)
	float Drag = 1.0;

	UPROPERTY(Category = Movement)
	float TurnDuration = 2.0;

	UPROPERTY(Category = Dash)
	float DashCooldown = 1.0;

	UPROPERTY(Category = Dash)
	float DashSpeed = 20000.0;

	UPROPERTY(Category = Soar)
	float SoarCooldown = 2.0;

	UPROPERTY(Category = Soar)
	float SoarSpeed = 5000.0;

	UPROPERTY(Category = Dive)
	float DiveCooldown = 1.0;

	UPROPERTY(Category = Dive)
	float DiveSpeed = 8000.0;

	UPROPERTY(Category = Camera)
	float CameraOffsetRight = 200.0;

	UPROPERTY(Category = Camera)
	float CameraOffsetUp = 100.0;
}
