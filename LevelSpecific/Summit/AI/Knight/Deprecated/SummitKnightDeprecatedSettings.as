class USummitKnightDeprecatedSettings : UHazeComposableSettings
{
	// Cost of the leap attack in gentleman system
	UPROPERTY(Category = "Leap")
	EGentlemanCost LeapGentlemanCost = EGentlemanCost::Large;

	UPROPERTY(Category = "Leap")
	float LeapTokenCooldown = 1.0;

	UPROPERTY(Category = "Leap")
	float LeapCooldown = 3.0;

	UPROPERTY(Category = "Leap")
	float LeapMinRange = 0;

	UPROPERTY(Category = "Leap")
	float LeapMaxRange = 1800;

	UPROPERTY(Category = "Leap")
	float LeapTelegraphDuration = 0.7;

	UPROPERTY(Category = "Leap")
	float LeapAnticipationDuration = 0.2;

	UPROPERTY(Category = "Leap")
	float LeapAttackDuration = 1.0;

	UPROPERTY(Category = "Leap")
	float LeapRecoveryDuration = 1.1;

	UPROPERTY(Category = "Leap")
	float LeapMoveSpeed = 4000;

	// Cost of the charge attack in gentleman system
	UPROPERTY(Category = "Charge")
	EGentlemanCost ChargeGentlemanCost = EGentlemanCost::Large;

	UPROPERTY(Category = "Charge")
	float ChargeTokenCooldown = 1.0;

	UPROPERTY(Category = "Charge")
	float ChargeCooldown = 1.4;

	UPROPERTY(Category = "Charge")
	float ChargeMoveSpeed = 5000;

	UPROPERTY(Category = "Charge")
	float ChargeTelegraphDuration = 0.6;

	UPROPERTY(Category = "Charge")
	float ChargeAnticipationDuration = 0.25;

	UPROPERTY(Category = "Charge")
	float ChargeAttackDuration = 0.8;

	UPROPERTY(Category = "Charge")
	float ChargeRecoveryDuration = 0.8;

	UPROPERTY(Category = "Charge")
	float ChargeMinRange = 0;

	UPROPERTY(Category = "Charge")
	float ChargeMaxRange = 3800;

	// Cost of the sweep attack in gentleman system
	UPROPERTY(Category = "Sweep")
	EGentlemanCost SweepGentlemanCost = EGentlemanCost::Large;

	UPROPERTY(Category = "Sweep")
	float SweepTokenCooldown = 1.0;

	UPROPERTY(Category = "Sweep")
	float SweepCooldown = 1.5;

	UPROPERTY(Category = "Sweep")
	float SweepMoveSpeed = 1000;

	UPROPERTY(Category = "Sweep")
	float SweepTelegraphDuration = 0.4;

	UPROPERTY(Category = "Sweep")
	float SweepAnticipationDuration = 0.15;

	UPROPERTY(Category = "Sweep")
	float SweepAttackDuration = 0.6;

	UPROPERTY(Category = "Sweep")
	float SweepRecoveryDuration = 0.4;

	UPROPERTY(Category = "Sweep")
	float SweepMinRange = 0;

	UPROPERTY(Category = "Sweep")
	float SweepMaxRange = 1000;

	// How long after stopped being sprayed we release the shield
	UPROPERTY(Category = "Acid|Shield")
	float AcidShieldRecoveryDuration = 1.25;

	UPROPERTY(Category = "Acid|Shield")
	bool AcidShieldRegenerate = true;

	// How long after stopped being sprayed we stop dodging, if we haven't started doding yet
	UPROPERTY(Category = "Acid|Dodge")
	float AcidDodgeInterruptDuration = 0.1;

	// How long after stopped being sprayed we stop dodging
	UPROPERTY(Category = "Acid|Dodge")
	float AcidDodgeRecoveryDuration = 0.75;

	// How long we need to be sprayed before dodging
	UPROPERTY(Category = "Acid|Dodge")
	float AcidDodgeActivationDuration = 1.5;

	// How long we should not have been spray before we reset AcidDodgeActivationDuration
	UPROPERTY(Category = "Acid|Dodge")
	float AcidDodgeResetDuration = 1.25;

	// How fast we move during a dodge
	UPROPERTY(Category = "Acid|Dodge")
	float AcidDodgeMoveSpeed = 3000.0;

	UPROPERTY(Category = "ProximityFocus")
	float ProximityFocusRange = 2500.0;

	UPROPERTY(Category = "ProximityFocus")
	float ProximityFocusChaseMoveSpeed = 600.0;
};