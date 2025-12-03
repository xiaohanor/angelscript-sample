class UMagnetDroneAttachedSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Surface")
	bool bOnlyAlignWithMagneticContacts = true;

	UPROPERTY(Category = "Surface|Movement")
	float Acceleration = 7000;

	UPROPERTY(Category = "Surface|Movement")
	float Deceleration = 3000;

	UPROPERTY(Category = "Surface|Movement")
	float MaxHorizontalSpeed = 600;

	UPROPERTY(Category = "Surface|Movement")
	float MaxSpeedDeceleration = 2000;

	UPROPERTY(Category = "Surface|Movement")
	float ReboundMultiplier = 1.5;

	UPROPERTY(Category = "Surface|Dashing")
	float DashMaximumSpeed = 700.0;

	UPROPERTY(Category = "Surface|Dashing")
	float DashInputBufferWindow = 0.08;

	UPROPERTY(Category = "Surface|Dashing")
	float DashCooldown = 0.2;

	UPROPERTY(Category = "Surface|Dashing")
	float DashDuration = 0.2;

	UPROPERTY(Category = "Surface|Dashing")
	float DashExitSpeed = 2000.0;

	UPROPERTY(Category = "Surface|Dashing")
	float DashSprintExitBoost = 50.0;

	UPROPERTY(Category = "Surface|Dashing")
	float DashEnterSpeed = 1000.0;

	UPROPERTY(Category = "Surface|Dashing")
	float DashTurnDuration = 0.75;

	UPROPERTY(Category = "Detaching")
	bool bAlignWithNonMagneticFlatGround = true;

	UPROPERTY(Category = "Detaching")
	float AlignWithNonMagneticFlatGroundAngleThreshold = 45.0;

	UPROPERTY(Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> ShakeClass_Attached;

	UPROPERTY(Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> ShakeClass_Detached;
};