UCLASS(Abstract)
class UMaxSecurityLaserCutterEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Spawn() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChargeUpStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChargeUpStopped() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LaserActivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LaserDeactivated() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LaserImpacting(FMaxSecurityLaserCutterImpactData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Hacked() {}
}

struct FMaxSecurityLaserCutterImpactData
{
	UPROPERTY()
	FHitResult HitResult;

	UPROPERTY()
	bool bIsImpactingWeakPoint = false;
}