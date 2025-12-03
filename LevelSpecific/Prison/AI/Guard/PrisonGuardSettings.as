class UPrisonGuardSettings : UHazeComposableSettings
{
	// Cost of melee attack in gentleman system
	UPROPERTY(Category = "Attack")
	EGentlemanCost AttackGentlemanCost = EGentlemanCost::Small;

	UPROPERTY(Category = "Attack")
	float AttackRange = 800.0;

	UPROPERTY(Category = "Attack")
	float AttackTokenCooldown = 0.8;

	UPROPERTY(Category = "Attack")
	float AttackCooldown = 0.5;

	UPROPERTY(Category = "Attack")
	float AttackHitExtraRange = 500.0;

	UPROPERTY(Category = "Attack")
	float AttackHitRadiusStart = 60.0;

	UPROPERTY(Category = "Attack")
	float AttackHitRadiusEnd = 400.0;

	UPROPERTY(Category = "Attack")
	float AttackDamage = 0.9;

	UPROPERTY(Category = "Attack")
	float AttackKnockbackDuration = 0.5;

	UPROPERTY(Category = "Attack")
	float AttackKnockbackDistance = 120.0;

	UPROPERTY(Category = "Targeting")
	float TargetingReactionTime = 0.8;

	UPROPERTY(Category = "Tracking")
	float TrackTargetRange = 4000.0;

	UPROPERTY(Category = "Tracking")
	float SpineTrackTargetRange = 1200.0;

	UPROPERTY(Category = "Tracking")
	float SpineTrackTargetMaxYaw = 120.0;

	UPROPERTY(Category = "HitByDrone")
	float HitByDroneStunnedDuration = 1.0;

	UPROPERTY(Category = "MagneticPush")
	float MagneticBurstStunnedDuration = 2.0;

	UPROPERTY(Category = "MagneticPush")
	int MagneticBurstsToKill = 1;

	UPROPERTY(Category = "MagneticPush")
	float MagneticPushForce = 1000.0;

	UPROPERTY(Category = "MagneticPush")
	float MagneticPushUpwardsBoost = 1000.0;

	UPROPERTY(Category = "Death")
	float ExplosionDeathForce = 2000.0;

	UPROPERTY(Category = "Death")
	float ExplosionDeathUpwardsBoost = 1000.0;

	UPROPERTY(Category = "Death")
	float DefaultDeathForce = 500.0;

	UPROPERTY(Category = "Death")
	float DefaultDeathUpwardsBoost = 0.0;

	UPROPERTY(Category = "Movement")
	float StepLength = 40.0;

	UPROPERTY(Category = "Movement")
	float MovingMinDurationBeforeTurning = 0.2;

	UPROPERTY(Category = "Movement")
	float MovingTurnRate = 40.0;
}

