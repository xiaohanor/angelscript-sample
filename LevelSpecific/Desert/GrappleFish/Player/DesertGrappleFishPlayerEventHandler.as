UCLASS(Abstract)
class UDesertGrappleFishPlayerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunchFromGrappleFish() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartGrappleToFish() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartRidingFish() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinalJumpDetachFromFish() {}
};