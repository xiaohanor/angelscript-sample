class USkylineAttackShipSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Movement")
	float MovementSpeed = 500.0;

	UPROPERTY(Category = "Movement")
	float Drag = 2.0;

	UPROPERTY(Category = "Movement")
	float LookAtSpeed = 20.0;

	UPROPERTY(Category = "Movement")
	float LookAtDrag = 8.0;

	UPROPERTY(Category = "Attack")
	float MinLongRangeAttacks = 22000.0;

	UPROPERTY(Category = "Attack")
	int NumOfProjectiles = 5;

	UPROPERTY(Category = "Movement")
	float Gravity = 980.0;

	UPROPERTY(Category = "Shield")
	float ShieldHP = 1.0;
}