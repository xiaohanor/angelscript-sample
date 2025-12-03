class UIslandZoomBotSettings : UHazeComposableSettings
{
	// Cost of melee attack in gentleman system
	UPROPERTY(Category = "Gentleman")
	EGentlemanCost ChargeGentlemanCost = EGentlemanCost::Medium;

	UPROPERTY(Category = "Charge")
	float ChargeTelegraphDuration = 2.0;

	UPROPERTY(Category = "Charge")
	float ChargeTelegraphHeight = 300.0;

	UPROPERTY(Category = "Charge")
	float ChargeHitRadius = 80.0;

	UPROPERTY(Category = "Charge")
	float ChargeDamage = 0.1;

	UPROPERTY(Category = "Charge")
	float ChargeTokenCooldown = 3.0;

	UPROPERTY(Category = "Stun")
	float ShieldBusterStunTime = 1.0;
}

/** Zoombots instantly dies from nunchucks */
asset ZoomBotNunchuckDamageSettings of UIslandNunchuckDamageSettings
{
	Light = 1.0;
	Normal = 1.0;
	Heavy = 1.0;
}

