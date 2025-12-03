class USummitStoneBeastZapperSettings : UHazeComposableSettings
{
	// Cost of attack in gentleman system
	UPROPERTY(Category = "Attack")
	EGentlemanCost AttackGentlemanCost = EGentlemanCost::Large;
	
	UPROPERTY(Category = "Attack")
	float AttackTokenCooldown = 5.0;

	UPROPERTY(Category = "Attack")
	float AttackTokenPersonalCooldown = 7.0;

	UPROPERTY(Category = "Attack")
	float AttackRange = 5000.0;
	
	UPROPERTY(Category = "Attack")
	float AttackDamageRadius = 125.0;

	UPROPERTY(Category = "Attack")
	float AttackTelegraphDuration = 1.5;
	
	UPROPERTY(Category = "Attack")
	int AttackSpawnNum = 3;

	UPROPERTY(Category = "Attack")
	float AttackSpawnRate = 0.5;
	
	// Duration after attack burst in which shield is still active
	UPROPERTY(Category = "Attack")
	float AttackRecovery = 0.25;

	// When player is this near the LightningCrystal, the lightning activates
	UPROPERTY(Category = "Attack|LightningCrystals")
	float LightningCrystalTelegraphDuration = 0.5;

	// When player is this near the LightningCrystal, the lightning activates
	UPROPERTY(Category = "Attack|LightningCrystals")
	float LightningCrystalProximityActivationRadius = 50.0;

	UPROPERTY(Category = "Attack|LightningCrystals")
	float LightningCrystalSpeed = 300.0;

	UPROPERTY(Category = "Attack|LightningCrystals")
	float LightningCrystalLifetime = 3.0;

	UPROPERTY(Category = "Recovery")
	float VulnerabilityDuration = 5.5;


	UPROPERTY(Category = "BeamAttack")
	float BeamAttackSpeed = 1200.0;
	
	UPROPERTY(Category = "BeamAttack")
	float BeamDecalScaleSpeed = 20.0;

	UPROPERTY(Category = "BeamAttack")
	float BeamDecalMaxScale = 30.0;

	UPROPERTY(Category = "BeamAttack")
	float BeamAttackTelegraphDuration = 1.5;

	// Number of VFX electrical flashes while performing beam attack (effects attack duration)
	UPROPERTY(Category = "BeamAttack")
	int BeamAttackFlashEffectSpawnNum = 4;

	// Interval between VFX electrical flashes while performing beam attack (effects attack duration)
	UPROPERTY(Category = "BeamAttack")
	float BeamAttackFlashEffectSpawnRate = 0.5;

	// Duration after attack in which shield is still active and animation is running
	UPROPERTY(Category = "BeamAttack")
	float BeamAttackRecovery = 2.0;

	UPROPERTY(Category = "BeamAttack")
	float BeamAttackDuration = 2.0; //Use this instead eller?
}