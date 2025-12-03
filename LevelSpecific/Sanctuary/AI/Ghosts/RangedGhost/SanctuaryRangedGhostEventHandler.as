UCLASS(Abstract)
class USanctuaryRangedGhostEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAddTargetIndicator(FSanctuaryRangedGhostAddTargetIndicatorParameters Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRemoveTargetIndicator(FSanctuaryRangedGhostRemoveTargetIndicatorParameters Params)
	{
	}
}

struct FSanctuaryRangedGhostAddTargetIndicatorParameters
{
	FSanctuaryRangedGhostAddTargetIndicatorParameters(int InProjectileIndex, FVector InTargetLocation)
	{
		ProjectileIndex = InProjectileIndex;
		TargetLocation = InTargetLocation;
	}

	UPROPERTY()
	int ProjectileIndex;
	UPROPERTY()
	FVector TargetLocation;
}

struct FSanctuaryRangedGhostRemoveTargetIndicatorParameters
{
	FSanctuaryRangedGhostRemoveTargetIndicatorParameters(int InProjectileIndex)
	{
		ProjectileIndex = InProjectileIndex;
	}

	UPROPERTY()
	int ProjectileIndex;
}