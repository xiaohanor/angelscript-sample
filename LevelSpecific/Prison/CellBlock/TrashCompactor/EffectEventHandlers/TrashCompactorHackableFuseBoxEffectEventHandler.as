UCLASS(Abstract)
class UTrashCompactorHackableFuseBoxEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HackStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void HackEnded() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ActivateCharge() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChargeCollision() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChargeReachedEnd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void RotateObstacles() {}
}