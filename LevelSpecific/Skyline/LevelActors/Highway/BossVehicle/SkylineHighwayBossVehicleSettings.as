class USkylineBossVehicleSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Volley")
	int VolleyProjectileAmount = 8;

	UPROPERTY(Category = "Attack")
	float VolleyProjectileInterval = 0.15;

	UPROPERTY(Category = "Volley")
	float VolleyLaunchGravity = 982.0 * 25.0;

	UPROPERTY(Category = "Volley")
	float VolleyLaunchHeight = 500.0;

	UPROPERTY(Category = "Volley")
	float VolleyAttackCooldown = 1.0;

	UPROPERTY(Category = "Volley")
	float VolleyTelegraphDuration = 0.75;

	UPROPERTY(Category = "Volley")
	float VolleyMaxAttackRange = 30000.0;

	UPROPERTY(Category = "Volley")
	float VolleyMinAttackRange = 300.0;

	UPROPERTY(Category = "Barrage")
	float BarrageTelegraphDuration = 0.75;

	UPROPERTY(Category = "Barrage")
	float BarrageProjectileSideOffsetMax = 250;
}
