struct FSkylineMagnetCraneLockImpactParams
{
	UPROPERTY()
	ASkylineMagnetCrane Crane;
}

UCLASS(Abstract)
class USkylineMagnetCraneEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLockImpact(FSkylineMagnetCraneLockImpactParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnClawsFinished() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitGround() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartReturn() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReturnFinished() {}	
}