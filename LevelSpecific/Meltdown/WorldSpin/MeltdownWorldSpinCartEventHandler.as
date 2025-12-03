struct FMeltdownWorldSpinCartMovingEvent
{
	FMeltdownWorldSpinCartMovingEvent(UStaticMeshComponent _Cart)
	{
		Cart = _Cart;
	}

	UPROPERTY()
	UStaticMeshComponent Cart;
}


UCLASS(Abstract)
class UMeltdownWorldSpinCartEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CartMoving(FMeltdownWorldSpinCartMovingEvent Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CartNotMoving(FMeltdownWorldSpinCartMovingEvent Params) {}
};