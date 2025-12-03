class USkylineBossChaserSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Movement")
	float Gravity = 3000.0;

	UPROPERTY(Category = "Movement")
	float Speed = 6000.0;

	UPROPERTY(Category = "Movement")
	float AirControl = 0.3;

	UPROPERTY(Category = "Movement")
	float GroundDrag = 1.0;

	UPROPERTY(Category = "Movement")
	float AirDrag = 0.2;

	UPROPERTY(Category = "Movement")
	float GroundBounce = 0.3;

	UPROPERTY(Category = "Movement")
	float WallBounce = 0.3;

	UPROPERTY(Category = "Movement")
	float MaxLeanAngle = 45.0;

	UPROPERTY(Category = "Attack")
	float AttackRange = 5000.0;

	UPROPERTY(Category = "Attack")
	float AttackCooldown = 3.0;

	UPROPERTY(Category = "Attack")
	float AttackDuration = 5.0;

	UPROPERTY(Category = "Attack")
	float AttackFireInterval = 0.1;

	UPROPERTY(Category = "Health")
	float Health = 5.0;
}