class USmasherSettings : UHazeComposableSettings
{
	UPROPERTY()
	float AttackRange = 1200.0;

	UPROPERTY()
	float AttackMaxAngleDegrees = 60.0;

	UPROPERTY()
	float AttackCooldown = 0.5;

	UPROPERTY()
	float AttackAnimDurationScale = 1.0; 

	UPROPERTY()
	float AttackHitRadius = 900.0;

	UPROPERTY()
	float AttackMovementReachFactor = 0.5;

	UPROPERTY()
	float AttackDamage = 0.9;

	UPROPERTY()
	float AttackHitStumbleDuration = 0.5;

	UPROPERTY()
	FVector AttackHitStumbleDistance = FVector(1500.0, 0.0, 300.0);

	// Cost of attack in gentleman system
	UPROPERTY(Category = "Cost")
	EGentlemanCost GentlemanCost = EGentlemanCost::Large;

	UPROPERTY()
	float AttackGentlemanCooldown = 1.0;

	UPROPERTY()
	float AttackSuccessExtraCooldown = 0.5;

	UPROPERTY()
	float JumpAttackGentlemanCooldown = 1.0;


	UPROPERTY()
	float JumpAttackRange = 4000.0;

	UPROPERTY()
	float JumpAttackMinRange = 1200.0;

	UPROPERTY()
	float JumpAttackMaxAngleDegrees = 25.0;

	UPROPERTY()
	float JumpAttackCooldown = 1.0;

	UPROPERTY()
	float JumpAttackAnimDurationScale = 1.0;

	UPROPERTY()
	float JumpAttackHeight = 2800.0;

	UPROPERTY()
	float JumpAttackImpactOffset = 150.0;

	UPROPERTY()
	float JumpAttackRadius = 600.0;

	UPROPERTY()
	float JumpAttackDamage = 0.9;

	UPROPERTY()
	FVector JumpAttackHitImpulse = FVector(1000.0, 0.0, 1000.0);

	// How long between starting to dig down and disappearing
	UPROPERTY()
	float DigStartDuration = 1.0;

	// How long disappeared ("digging")
	UPROPERTY()
	float DigDuration = 1.0;

	// How long between telegraphing and appearance
	UPROPERTY()
	float DigAppearDuration = 0.25;

	// We prefer to keep this much space from another team member (another enemy) when choosing our appear location
	UPROPERTY()
	float DigAppearClearRange = 1000.0;
};

asset StomperSettings of USmasherSettings
{
	AttackHitRadius = 500.0;
	AttackMovementReachFactor = 1.2;

	JumpAttackMinRange = 2000.0;
	JumpAttackHeight = 1000.0;
	JumpAttackImpactOffset = 100.0;
}

asset StomperBasicSettings of UBasicAISettings
{
	// Higher move speed to compensate for having movement paused during parts of animation
	ChaseMoveSpeed = 1400.0;
}