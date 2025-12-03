struct FStoneBeastThrowingRockParams
{
	UPROPERTY()
	FVector Location;
}

UCLASS(Abstract)
class UStoneBeastThrowingRockEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartRockPickup(FStoneBeastThrowingRockParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void UpdateRockPickupLocation(FStoneBeastThrowingRockParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ThrowRockPickup(FStoneBeastThrowingRockParams Params)
	{
	}
};