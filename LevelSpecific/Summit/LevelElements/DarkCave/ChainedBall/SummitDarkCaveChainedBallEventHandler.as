struct FSummitDarkCaveResetParams
{
	UPROPERTY()
	FVector FromLocation;

	UPROPERTY()
	FVector ToLocation;

	FSummitDarkCaveResetParams(FVector NewFromLocation, FVector NewToLocation)
	{
		FromLocation = NewFromLocation;
		ToLocation = NewToLocation;
	}
}

struct FSummitDarkCaveChainedBallImpactParams
{
	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	float SpeedIntoImpact;

	UPROPERTY()
	UPhysicalMaterial ImpactedMaterial;
}

struct FSummitDarkCaveChainedBallImpactedByRollParams
{
	UPROPERTY()
	FVector RollImpactLocation;

	UPROPERTY()
	float LaunchSpeed;

	UPROPERTY()
	FVector LaunchDir;
}

struct FSummitDarkCaveChainedBallLandedInGoalParams
{
	UPROPERTY()
	FVector GoalLocation;
}

UCLASS(Abstract)
class USummitDarkCaveChainedBallEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBallReset(FSummitDarkCaveResetParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBallImpactedGround(FSummitDarkCaveChainedBallImpactParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBallImpactedWall(FSummitDarkCaveChainedBallImpactParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBallImpactedByRoll(FSummitDarkCaveChainedBallImpactedByRollParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBallLandedInGoal(FSummitDarkCaveChainedBallLandedInGoalParams Params) {}

	ASummitDarkCaveChainedBall Ball;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Ball = Cast<ASummitDarkCaveChainedBall>(Owner);
		MoveComp = UHazeMovementComponent::Get(Ball);
	}

	UFUNCTION(BlueprintPure, Category = "Chained Ball")
	float GetBallSpeed() const
	{
		return MoveComp.Velocity.Size();
	}

	UFUNCTION(BlueprintPure, Category = "Chained Ball")
	bool IsOnGround() const
	{
		return MoveComp.IsOnAnyGround();
	}

	UFUNCTION(BlueprintPure, Category = "Chained Ball")
	bool IsInAir() const 
	{
		return MoveComp.IsInAir();
	}
};