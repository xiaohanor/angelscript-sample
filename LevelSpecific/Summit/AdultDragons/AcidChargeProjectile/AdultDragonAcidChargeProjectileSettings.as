class UAdultDragonAcidChargeProjectileSettings : UHazeComposableSettings
{
	// Socket name on the dragon that acid should spray from
	UPROPERTY()
	FName ShootSocket = n"Jaw";

	// Offset from the socket on the dragon that acid should spray from
	UPROPERTY()
	FVector ShootSocketOffset = FVector(50.0, 0, 0);

	UPROPERTY()
	float MoveSpeed = 45000.0;

	UPROPERTY()
	float Cooldown = 0.5;

	UPROPERTY()
	float MaxChargeDuration = 0.5;

	UPROPERTY()
	float MinRadius = 50;

	UPROPERTY()
	float MaxRadius = 300;

	UPROPERTY()
	bool bAutoShootOnFullCharge = false;
}