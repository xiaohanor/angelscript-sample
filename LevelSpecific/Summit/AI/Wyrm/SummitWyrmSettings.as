class USummitWyrmSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Shape")
	float StartLength = 40000.0;

	UPROPERTY(Category = "Shape")
	int NumSegments = 60;

	UPROPERTY(Category = "Shape")
	float SegmentHeightOffset = -700.0;

	UPROPERTY(Category = "Shape")
	float TailScale = 8.0;

	UPROPERTY(Category = "Shape")
	float WidestFraction = 0.1;

	UPROPERTY(Category = "Shape")
	float MaxGirth = 1.5;
 
	UPROPERTY(Category = "Shape")
	float TailGirth = 0.3; 


	UPROPERTY(Category = "Movement")
	float UndulationAmount = 0.25;

	UPROPERTY(Category = "Movement")
	float UndulationFrequency = 2.5;

	UPROPERTY(Category = "Movement")
	float TurnRateFactor = 0.1;


	UPROPERTY(Category = "Roam")
	float RoamSpeed = 15000.0;

	UPROPERTY(Category = "Roam")
	float RoamAngle = 30.0;

	UPROPERTY(Category = "Roam")
	float RoamMaxRange = 45000.0;

	UPROPERTY(Category = "Roam")
	float RoamHeightMax = 15000;

	UPROPERTY(Category = "Roam")
	float RoamHeightMin = -5000;


	UPROPERTY(Category = "Engage")
	float EngageTurnRange = 40000;

	UPROPERTY(Category = "Engage")
	float EngageSpeed = 27500;
		
	UPROPERTY(Category = "Engage")
	float EngageMaxRange = 200000;


	UPROPERTY(Category = "AttackPositioning")
	float AttackPositioningRange = 200000;

	UPROPERTY(Category = "AttackPositioning")
	float AttackPositioningCameraExtraDistance = 3000;

	UPROPERTY(Category = "AttackPositioning")
	float AttackPositioningCameraBlendTime = 5;

	UPROPERTY(Category = "AttackPositioning")
	FVector AttackPositioningTargetOffset = FVector(-750, 1000, -1000);

	UPROPERTY(Category = "AttackPositioning")
	float AttackPositioningMoveSpeed = 27500;

	UPROPERTY(Category = "AttackPositioning")
	float AttackPositioningSlowDownRadius = 2500;


	UPROPERTY(Category = "Attack")
	float AttackInPositionMinDuration = 2.0;

	UPROPERTY(Category = "Attack")
	float AttackTelegraphDuration = 1.5;

	UPROPERTY(Category = "Attack")
	float AttackEvadeMinDuration = 2.0;

	UPROPERTY(Category = "Attack")
	float AttackDamagePerSecond = 0.05;

	UPROPERTY(Category = "Attack")
	float AttackDamageInterval = 0.2;


	UPROPERTY(Category = "Charge")
	float ChargeSpeed = 80000.0;

	UPROPERTY(Category = "Charge")
	float ChargeMaxAngle = 30.0;

	UPROPERTY(Category = "Charge")
	float ChargeMaxRange = 80000.0;

	UPROPERTY(Category = "Charge")
	float ChargeMinRange = 15000.0;

	UPROPERTY(Category = "Charge")
	float ChargeTelegraphDuration = 1.5;

	UPROPERTY(Category = "Charge")
	float ChargeTelegraphRise = 2.0;

	UPROPERTY(Category = "Charge")
	float ChargeTelegraphSpeed = 22000.0;

	UPROPERTY(Category = "Charge")
	float ChargeTrackDuration = 2.0;

	UPROPERTY(Category = "Charge")
	float ChargeMaxDuration = 8.0;

	UPROPERTY(Category = "Charge")
	float ChargeCooldown = 5.0;


	UPROPERTY(Category = "Recover")
	float RecoverSpeed = 10000.0;

	UPROPERTY(Category = "Recover")
	float RecoverDuration = 8.0;

	UPROPERTY(Category = "Recover")
	float FollowSplineSpeed = 10500.0;


	UPROPERTY(Category = "HurtReaction")
	float HurtReactionMoveSpeed = 9500.0;

	UPROPERTY(Category = "HurtReaction")
	float HurtReactionDuration = 2.0;

	UPROPERTY(Category = "HurtReaction")
	float HurtReactionSegmentReattachDuration = 4.0;

	UPROPERTY(Category = "HurtReaction")
	float HurtReactionMetalMeltDissolveDuration = 0.5;

	UPROPERTY(Category = "HurtReaction")
	int HurtReactionAcidHitOffsetSteps = 1; // Increase hit size for Acid on metal.
};
