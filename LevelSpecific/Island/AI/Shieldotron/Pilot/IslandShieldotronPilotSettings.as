class UIslandShieldotronPilotSettings : UHazeComposableSettings
{
	// Orb Attack

	UPROPERTY(Category = "Combat|OrbAttack")
	float OrbAttackMinRange = 100.0;		

	UPROPERTY(Category = "Combat|OrbAttack")
	float OrbAttackMaxRange = 7000.0;

	UPROPERTY(Category = "Combat|OrbAttack")
	int OrbAttackBurstNumber = 1;

	UPROPERTY(Category = "Combat|OrbAttack")
	float OrbProjectileExpirationTime = 6.0;
	
	// When past target remaining expiration time will be truncated to this value
	UPROPERTY(Category = "Combat|OrbAttack")
	float OrbProjectileReducedExpirationTime = 0.5;

	UPROPERTY(Category = "Combat|OrbAttack")
	float OrbProjectileLaunchSpeed = 1000.0;
	
	UPROPERTY(Category = "Combat|OrbAttack")
	float OrbProjectileSpeed = 1000.0;

	// Homing steering force
	UPROPERTY(Category = "Combat|OrbAttack")
	float OrbHomingStrength = 40.0;

	// Homing max steering speed (prevents oscillation)
	UPROPERTY(Category = "Combat|OrbAttack")
	float OrbProjectileMaxPlanarHomingSpeed = 2000.0;

	UPROPERTY(Category = "Combat|OrbAttack")
	float OrbScaleTime = 1.5;	
}
