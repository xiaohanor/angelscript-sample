class USanctuaryGhostSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Attack|Charge")
	float ChargeRange = 1500.0;

	UPROPERTY(Category = "Attack|Charge")
	float ChargeMinRange = 750.0;

	UPROPERTY(Category = "Attack|Charge")
	float ChargeMaxAngleDegrees = 45.0;

	UPROPERTY(Category = "Attack|Charge")
	float ChargeCooldown = 3.0;

	UPROPERTY(Category = "Attack|Charge")
	float ChargeTokenCooldown = 3.0;

	// We move this factor * <distance to target> when attacking
	UPROPERTY(Category = "Attack|Charge")
	float ChargeTravelFactor = 1.5;

	UPROPERTY(Category = "Attack|Charge")
	float PostChargeHeight = 250.0;

	UPROPERTY(Category = "Attack|Charge")
	float PostChargeSpeed = 400.0;

	UPROPERTY(Category = "Attack|Charge")
	float ChargeTelegraphDuration = 0.97;
	UPROPERTY(Category = "Attack|Charge")
	float ChargeAnticipationDuration = 0.2;
	UPROPERTY(Category = "Attack|Charge")
	float ChargeHitDuration = 0.4;
	UPROPERTY(Category = "Attack|Charge")
	float ChargeRecoveryDuration = 0.27;

	UPROPERTY(Category = "Attack|Charge")
	float ChargeRadius = 80.0;

	UPROPERTY(Category = "Attack|Charge")
	float ChargeDamage = 0.2;

	UPROPERTY(Category = "Attack|Charge")
	float ChargeKnockdownDistance = 0.0; //1000.0; // No knockdown with 0.0, will use stumble instead.
	
	UPROPERTY(Category = "Attack|Charge")
	float ChargeKnockdownDuration = 2.0;

	UPROPERTY(Category = "Attack|Charge")
	float ChargeStumbleDistance = 100.0;

	UPROPERTY(Category = "Attack|Charge")
	float ChargeStumbleDuration = 1.0;

	// Cost of attack in gentleman system
	UPROPERTY(Category = "Attack|Charge")
	EGentlemanCost ChargeGentlemanCost = EGentlemanCost::Small;

	UPROPERTY(Category = "Circle")
	float CircleEnterRange = 900.0;

	UPROPERTY(Category = "Circle")
	float CircleMaxRange = 1500.0;

	UPROPERTY(Category = "Circle")
	float CircleDistance = 800.0;

	UPROPERTY(Category = "Circle")
	float CircleHeight = 100.0;

	UPROPERTY(Category = "Circle")
	float CircleWobble = 100.0;

	UPROPERTY(Category = "Circle")
	float CircleSpeed = 600.0;

	UPROPERTY(Category = "Recover")
	float RecoverDuration = 1.33;
};

