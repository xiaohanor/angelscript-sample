struct FMeltdownScreenWalkWoodenBox 
{
	FMeltdownScreenWalkWoodenBox(UStaticMeshComponent _WoodenBox)
	{
		WoodenBox = _WoodenBox;
	}

	UPROPERTY()
	UStaticMeshComponent WoodenBox;
}


UCLASS(Abstract)
class UMeltdownScreenWalkConveyorWoodenBoxEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Impact() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void CollapseDropDownHit() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Stomped(FMeltdownScreenWalkWoodenBox Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Destroy() {}
};