struct FSummitFruitPressOnHitByDragonParams
{
	UPROPERTY()
	FVector HitLocation;

	UPROPERTY()
	FVector HitNormal;
}

UCLASS(Abstract)
class USummitFruitPressEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitByDragon(FSummitFruitPressOnHitByDragonParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoppedRotating()
	{
	}
};