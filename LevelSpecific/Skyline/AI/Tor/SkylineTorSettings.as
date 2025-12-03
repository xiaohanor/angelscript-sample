class USkylineTorSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Movement")
	float AnimationMovementTurnDuration = 0.5;

	// Impulse speed of projectile
	UPROPERTY(Category = "Hammer")
	float HammerImpactSpeed = 1500.0;

	UPROPERTY(Category = "Hammer")
	float HammerVolleyTelegraphDuration = 1.3;

	UPROPERTY(Category = "Hammer")
	EGentlemanCost HammerImpactGentlemanCost = EGentlemanCost::Large;

	UPROPERTY(Category = "Hammer")
	float HammerImpactMinAttackRange = 500.0;

	UPROPERTY(Category = "Hammer")
	float HammerImpactHomingStopWithinDistance = 600;

	UPROPERTY(Category = "Hammer")
	float HammerImpactPlayerDamage = 0.9;

	UPROPERTY(Category = "Hammer")
	float HammerImpactNpcDamage = 1.5;

	UPROPERTY(Category = "Cooldown")
	float HammerVolleyCooldown = 1.5;

	UPROPERTY(Category = "Cooldown")
	float HammerImpactTokenCooldown = 3.0;

	UPROPERTY(Category = "Hover")
	float HoverHeight = 500;

	UPROPERTY(Category = "Hover")
	float HoverMinHeight = 400;

	UPROPERTY(Category = "Gravity Blade")
	float GravityBladeHitMoveFraction = 1.0;

	UPROPERTY(Category = "Gravity Blade")
	float GravityBladeTorDamage = 0.01;

	UPROPERTY(Category = "Gravity Blade")
	float GravityBladeHammerDamage = 0.02;

	UPROPERTY(Category = "Follow Hammer")
	float FollowHammerMinRange = 500;

	UPROPERTY(Category = "Follow Hammer")
	float FollowHammerMoveSpeed = 500;

	UPROPERTY(Category = "WhipSlip")
	float WhipSlipTorDamage = 0.2;

	UPROPERTY(Category = "Debris")
	float DebrisTorDamage = 0.015;

	UPROPERTY(Category = "Smash")
	float SmashAmount = 1;

	UPROPERTY(Category = "Smash")
	float SmashCooldown = 3;

	UPROPERTY(Category = "Smash")
	float SmashMinimumRadius = 25;

	UPROPERTY(Category = "Smash")
	float SmashMaximumRadius = 3500;

	UPROPERTY(Category = "Smash")
	float SmashExpansionBaseSpeed = 350;

	UPROPERTY(Category = "Smash")
	float SmashExpansionIncrementalSpeed = 650;

	UPROPERTY(Category = "Smash")
	float SmashDamageWidth = 30;


	UPROPERTY(Category = "OpportunityAttack")
	FTorOpportunityAttackParams OpportunityAttack_0;
	default OpportunityAttack_0.HealthAfterSuccess = 0.5;
	default OpportunityAttack_0.HealthAfterFail = 0.75;

	UPROPERTY(Category = "OpportunityAttack")
	float OpportunityAttackPauseAfterFail = 2.0;

	UPROPERTY(Category = "OpportunityAttack")
	float OpportunityAttackDurationUntilFail = 3.0;

	UPROPERTY(Category = "OpportunityAttack")
	bool OpportunityAttackAllowHitStops = false;

	UPROPERTY(Category = "Whirlwind")
	float WhirlwindDuration = 8;

	UPROPERTY(Category = "BoloAttack")
	float BoloStartRotationSpeed = 200.0;

	UPROPERTY(Category = "BoloAttack")
	float BoloSpawnDistance = 100;

	UPROPERTY(Category = "BoloAttack")
	float BoloMinDistance = 150;

	UPROPERTY(Category = "BoloAttack")
	float BoloMaxDistance = 500;

	UPROPERTY(Category = "Stealing")
	bool ShieldBreakModeEnabled = true;
}

struct FTorOpportunityAttackParams
{
	float HealthAfterSuccess = 0.5;
	float HealthAfterFail = 1;
}
