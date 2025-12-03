class UPrisonGuardBotSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "HackedMovement")
	float HackedMovementIdealHeightOffsetUp = 400.0;

	UPROPERTY(Category = "HackedMovement")
	float HackedMovementIdealHeightOffsetDown = 100.0;

	UPROPERTY(Category = "HackedMovement")
	float HackedMovementAccelerationForward = 1200.0;

	UPROPERTY(Category = "HackedMovement")
	float HackedMovementAccelerationRight = 800.0;

	UPROPERTY(Category = "HackedMovement")
	float HackedMovementAccelerationUp = 1000.0;

	UPROPERTY(Category = "HackedMovement")
	float HackedMovementFriction = 1.2;

	UPROPERTY(Category = "HackedMovement")
	float HackedMovementRotationDuration = 0.5;

	UPROPERTY(Category = "Targeting")
	float TargetingReactionTime = 0.4;

	UPROPERTY(Category = "Targeting")
	float TargetingStayWithZoeDuration = 12.0;

	UPROPERTY(Category = "Chase")
	float ChaseMoveSpeed = 1000.0;

	UPROPERTY(Category = "Chase")
	float ChaseMinRange = 1200.0;

	UPROPERTY(Category = "Zap")
	float ZapAttackRange = 1500.0;

	UPROPERTY(Category = "Zap")
	float ZapAttackDuration = 0.5;

	UPROPERTY(Category = "Zap")
	float ZapAttackCooldown = 3.0;

	UPROPERTY(Category = "Zap")
	float ZapAttackDamageInterval = 0.1;

	UPROPERTY(Category = "Zap")
	float ZapAttackMioDamage = 0.25;

	UPROPERTY(Category = "Zap")
	float ZapAttackZoeDamage = 0.15;

	UPROPERTY(Category = "Zap")
	float ZapAttackAIDamagePerSecond = 1.0;

	UPROPERTY(Category = "Zap")
	float ZapAttackHackedMinDuration = 0.5;

	UPROPERTY(Category = "Zap")
	float ZapAttackHackedRange = 2000.0;

	UPROPERTY(Category = "Zap")
	float ZapAttackHackedHitAngle = 15.0;

	UPROPERTY(Category = "Zap")
	bool bZapAttackCanHitRegularGuards = false;

	// Cost of zapper attack in gentleman system
	UPROPERTY(Category = "Zap")
	EGentlemanCost ZapAttackGentlemanCost = EGentlemanCost::Small;

	UPROPERTY(Category = "HitReaction")	
	float HitreactionDuration = 0.3;

	UPROPERTY(Category = "Explode")
	float ExplodeTelegraphDuration = 1.0;

	UPROPERTY(Category = "Explode")
	float ExplodeTelegraphHeight = 300.0;

	// Local offset for charge destination
	UPROPERTY(Category = "Explode")
	FVector ExplodeChargeOffset = FVector(0.0, 0.0, 100.0);

	// How far away we can initiate the charge for when we want to explode
	UPROPERTY(Category = "Explode")
	float ExplodeChargeRange = 1000.0;

	// Movement speed during charge
	UPROPERTY(Category = "Explode")
	float ExplodeChargeMoveSpeed = 2500.0;

	// Keep moving towards target until within this range, then we charge straight ahead
	UPROPERTY(Category = "Explode")
	float ExplodeChargeTrackTargetRange = 400.0;

	// Trigger explosion when at this range
	UPROPERTY(Category = "Explode")
	float ExplodeDetonationRadius = 100.0;

	// Blast radius
	UPROPERTY(Category = "Explode")
	float ExplodeDamageRadius = 400.0;

	// Radius at which max damage is dealt (if BIG_NUMBER, damage is the same throughout above radius)
	UPROPERTY(Category = "Explode")
	float ExplodeDamageInnerRadius = BIG_NUMBER;

	UPROPERTY(Category = "Explode")
	float ExplodePlayerDamage = 0.5;

	UPROPERTY(Category = "Explode")
	float ExplodeAIDamage = 1.0;

	UPROPERTY(Category = "Explode")
	float ExplodeForce = 500.0;

	UPROPERTY(Category = "Explode")
	float ExplodeUpwardsBoostForce = 200.0;

	UPROPERTY(Category = "Explode")
	float ExplodeKnockdownDuration = 1.0;

	UPROPERTY(Category = "Explode")
	float ExplodeTokenCooldown = 3.0;

	// Don't try another explode charge for this long after last
	UPROPERTY(Category = "Explode")
	float ExplodeChargeCooldown = 3.0;

	// Never try to find a target to explode against longer than this
	UPROPERTY(Category = "Explode")
	float ExplodeChargeMaxDuration = 3.0;

	// Cost of explosion charge attack in gentleman system
	UPROPERTY(Category = "Explode")
	EGentlemanCost ExplodeGentlemanCost = EGentlemanCost::Medium;


	UPROPERTY(Category = "Recover")
	float RecoverDuration = 1.0;

	UPROPERTY(Category = "Recover")
	float RecoverMoveSpeed = 1000;


	UPROPERTY(Category = "Stun")
	float MagneticBurstStunTime = 2.0;

	UPROPERTY(Category = "Stun")
	float MagneticBurstStunForce = 2000.0;
}


