UCLASS(Abstract)
class UGravityBikeBladeBarrelEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	AGravityBikeBladeBarrel Barrel;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Barrel = Cast<AGravityBikeBladeBarrel>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGravityBikeAttached() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGravityBikeDetached() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDrop() {}
};