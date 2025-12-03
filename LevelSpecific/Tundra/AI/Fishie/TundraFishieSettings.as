class UTundraFishieSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Agitation")
	float AgitatedEmissiveStrength = 20.0;

	UPROPERTY(Category = "Agitation")
	float AgitatedEmissiveDuration = 1.0;

	UPROPERTY(Category = "Agitation")
	float CalmdownEmissiveDuration = 5.0;

	UPROPERTY(Category = "SwimBounce")
	float SwimBounceMoveSpeed = 600.0;

	UPROPERTY(Category = "SwimBounce")
	float SwimBounceTurnCooldown = 1.0;

	UPROPERTY(Category = "SwimBounce")
	float SwimBounceTurnDuration = 5.0;

	UPROPERTY(Category = "SwimBounce")
	float SwimBounceAvoidObstaclesDuration = 0.5;

	UPROPERTY(Category = "SplinePatrol")
	float SplinePatrolMovementSpeed = 600.0;

	// For non-looping splines, we start turning this far before spline end
	UPROPERTY(Category = "SplinePatrol")
	float SplinePatrolTurnRange = 120.0;

	UPROPERTY(Category = "SplinePatrol")
	float SplinePatrolTurnDuration = 5.0;

	UPROPERTY(Category = "Chase")
	float ChaseRangeAhead = 1200.0;

	UPROPERTY(Category = "Chase")
	float ChaseRangeBehind = 300.0;

	UPROPERTY(Category = "Chase")
	float ChaseRangeAbove = 1500.0;

	UPROPERTY(Category = "Chase")
	float ChaseRangeBelow = 800.0;

	UPROPERTY(Category = "Chase")
	float ChaseReactionPause = 0.5;

	UPROPERTY(Category = "Chase")
	float ChaseMoveSpeed = 2000.0;

	UPROPERTY(Category = "Chase")
	float ChaseLoseHiddenTargetDuration = 2.0;

	UPROPERTY(Category = "EatPlayer")
	float EatPlayerRange = 200.0;

	// Player is killed this soon after starting eat behaviour, or earlier if caught before
	UPROPERTY(Category = "EatPlayer")
	float EatPlayerMaxDelay = 0.5;

	// Return to regular movement after this time
	UPROPERTY(Category = "EatPlayer")
	float EatPlayerDuration = 3.0;

	UPROPERTY(Category = "EatPlayer")
	float EatPlayerMoveSpeed = 5000.0;

	UPROPERTY(Category = "EatPlayer")
	float EatPlayerReturnMoveSpeed = 300.0;

	UPROPERTY(Category = "EatPlayer")
	float EatPlayerReturnThreshold = 300.0;

	UPROPERTY(Category = "EatPlayer")
	float EatPlayerBodyLength = 600.0;

	UPROPERTY(Category = "EatPlayer")
	float PostEatPlayerResumeSwimAnimDuration = 1.5;

	UPROPERTY(Category = "Perception")
	float VisibilityTargetOffset = -40.0;
}