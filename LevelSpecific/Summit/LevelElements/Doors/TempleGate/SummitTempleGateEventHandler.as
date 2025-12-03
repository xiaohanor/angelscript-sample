struct FSummitTempleGateOnHitByRollParams
{
	UPROPERTY()
	FVector HitLocation;

	UPROPERTY()
	float SpeedTowardsHit;
}

UCLASS(Abstract)
class USummitTempleGateEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitByRollNotOpened(FSummitTempleGateOnHitByRollParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitByRollOpened(FSummitTempleGateOnHitByRollParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartedOpening()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinishedOpening()
	{
	}
};