class UBasicAIHealthSettings : UHazeComposableSettings
{
	// If > 0, when taking damage we never take any further damage until this many seconds has passed
	UPROPERTY(Category = "Damage")
	float TakeDamageCooldown = 0.0;

	// If false, we never suffer damage from friendly instigators (e.g. team members)
	UPROPERTY(Category = "Damage")
	bool bAllowFriendlyFire = false;

	// If dealt more damage than this, we show damage effect, e.g. 0 means we always show an effect when taking damage.
	UPROPERTY(Category = "Damage")
	float DamageEffectThreshold = 0.0;

	// If true, we take damage but never die. 
	UPROPERTY(Category = "Damage")
	bool bImmortal = false;
}

