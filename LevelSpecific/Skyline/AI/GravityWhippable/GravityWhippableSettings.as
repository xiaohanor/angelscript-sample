class UGravityWhippableSettings : UHazeComposableSettings
{
	// What's the maximum time we can be in a thrown state before we are automatically killed/destroyed
	UPROPERTY()
	float MaxThrownDuration = 2.0;

	// The thrown impulse force will be multiplied by this value
	UPROPERTY()
	float ThrownForceFactor = 1.0;

	// This much impulse force should will be added when lifting the target
	UPROPERTY()
	float LiftImpulse = 500.0;

	// Duration of landing state after being released (not thrown)
	UPROPERTY()
	float LandDuration = 1.0;

	// Air friction while lifted by gravity whip
	UPROPERTY()
	float LiftedGroundFriction = 12.0;

	// Ground friction while lifted by gravity whip
	UPROPERTY()
	float LiftedAirFriction = 8.0;

	// Threshold for vector size that causes the released target to be killed
	UPROPERTY()
	float DeathThrowThreshold = 2000.0;

	UPROPERTY(Category = "Damage")
	bool bEnableThrownDamage = true;

	UPROPERTY(Category = "Damage")
	float ThrownDamage = 0.5;

	UPROPERTY(Category = "Damage")
	EDamageType ThrownDamageType = EDamageType::Default;

	// If zero, only targets that are directly hit will be damaged
	UPROPERTY(Category = "Damage")
	float ThrownDamageRadius = 200.0;

	UPROPERTY(Category = "Impact")
	EGravityWhippableDeathType DeathType = EGravityWhippableDeathType::Velocity;

	UPROPERTY(Category = "Flinch")
	float WhipFlinchDuration = 1.5;
}

enum EGravityWhippableDeathType
{
	Impact,
	Velocity,
	VelocityAndImpact,
	MAX
}