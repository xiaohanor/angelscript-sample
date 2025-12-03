class UTundraGnatapultSettings : UHazeComposableSettings
{
	// High cost means fewer will attack at the same time, low cost allows more to do so.
	UPROPERTY(Category = "Attack")
	EGentlemanCost AttackGentlemanCost = EGentlemanCost::Large;

	UPROPERTY(Category = "Attack")
	float AttackGlobalCooldown = 2.0;

	UPROPERTY(Category = "Attack")
	float ProjectileSpeed = 1500.0;

	UPROPERTY(Category = "Attack")
	float ProjectileHeightFactor = 0.6;

	UPROPERTY(Category = "Attack")
	float ProjectileRemainAfterDestructionTime = 4.0; // For VFX

	UPROPERTY(Category = "Attack")
	float ProjectileBlastRadius = 300.0;

	UPROPERTY(Category = "Attack")
	float ProjectileDamage = 1.0;

	// How long we spend gathering a ball to fling before we can commence attack. Note that we may continue reloading past this if e.g. gentleman system delays attacks
	UPROPERTY(Category = "Reload")
	float ReloadMinDuration = 5.0;

	UPROPERTY(Category = "Reload")
	float ReloadDangerIndicatorDelay = 4.0;

	UPROPERTY(Category = "Positioning")
	float PositioningMoveSpeed = 400.0;

	UPROPERTY(Category = "Positioning")
	float PositioningDuration = 3.0;

	UPROPERTY(Category = "Positioning")
	FVector PositioningOnBodyCenter = FVector(2220.0, 80.0, 1500.0);

	UPROPERTY(Category = "Positioning")
	float PositioningOnBodyRadius = 0.0;
}