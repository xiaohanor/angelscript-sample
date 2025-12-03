class UAdultDragonSpikeProjectileSettings : UHazeComposableSettings
{
	// Socket name on the dragon that acid should spray from
	UPROPERTY()
	FName ShootSocket = n"Head";

	// Offset from the socket on the dragon that acid should spray from
	UPROPERTY()
	FVector ShootSocketOffset = FVector(50.0, 0, 0);

	UPROPERTY()
	float MoveSpeed = 42000.0;

	UPROPERTY()
	float Cooldown = 0.3;
}