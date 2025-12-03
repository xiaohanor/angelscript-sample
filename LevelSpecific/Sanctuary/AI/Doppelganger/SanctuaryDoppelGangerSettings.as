class USanctuaryDoppelgangerSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Reveal")
	float RevealDuration = 2.0;

	UPROPERTY(Category = "Reveal")
	float RevealScale = 1.2;

	UPROPERTY(Category = "Attack")
	float AttackRange = 600.0;

	UPROPERTY(Category = "Attack")
	float AttackMaxAngleDegrees = 45.0;

	UPROPERTY(Category = "Attack")
	float AttackCooldown = 2.0;

	// We move this factor * <distance to target> when attacking
	UPROPERTY(Category = "Attack")
	float AttackTravelFactor = 1.5;

	UPROPERTY(Category = "Attack")
	float AttackTelegraphDuration = 0.128;
	UPROPERTY(Category = "Attack")
	float AttackAnticipationDuration = 0.65;
	UPROPERTY(Category = "Attack")
	float AttackHitDuration = 0.44;
	UPROPERTY(Category = "Attack")
	float AttackRecoveryDuration = 0.6;

	UPROPERTY(Category = "Attack")
	float AttackRadius = 150.0;

	UPROPERTY(Category = "Attack")
	float AttackInnerRadius = 80.0;

	UPROPERTY(Category = "Attack")
	float AttackDamage = 1.0;

	UPROPERTY(Category = "Creepyness")
	float CreepynessDelay = 20.0;

	UPROPERTY(Category = "Creepyness|Blink")
	float CreepyBlinkDelay = 0.0;

	UPROPERTY(Category = "Creepyness|Blink")
	float CreepyBlinkDiscoverDuration = 0.5;

	UPROPERTY(Category = "Creepyness|Blink")
	float CreepyBlinkCooldown = 10.0;

	UPROPERTY(Category = "Creepyness|Blink")
	float CreepyBlinkViewMinRange = 180.0;

	UPROPERTY(Category = "MatchPause")
	float MatchPauseVelocityThreshold = 20.0;

	UPROPERTY(Category = "MatchPause")
	float MatchPauseStartDelay = 1.0;

	UPROPERTY(Category = "MatchPause")
	float MatchPauseEndDelay = 2.0;

	UPROPERTY(Category = "Stalking")
	float StalkerDistance = 100.0;

	UPROPERTY(Category = "Stalking")
	float StalkerCaughtCooldown = 3.0;

	UPROPERTY(Category = "Stalking")
	float StalkerCloseMaxDuration = 5.0;

	UPROPERTY(Category = "MatchPosition")
	float MatchPositionMaxSpeed = 500.0;

	UPROPERTY(Category = "MatchPosition")
	float MatchPositionMaxOffset = 800.0;

	UPROPERTY(Category = "MatchPosition")
	float MatchPositionOffsetUpdateInterval = 10.0;

	UPROPERTY(Category = "MatchJump")
	float MatchJumpDelay = 1.0;

	UPROPERTY(Category = "MatchJump")
	float MatchJumpCooldown = 0.5;

	UPROPERTY(Category = "MatchJump")
	float MatchJumpMinSpeed = 200.0;
};

