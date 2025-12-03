UCLASS(Abstract)
class USkylineTorPulseEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpact(FSkylineTorPulseEventHandlerOnImpactData Data) {}
}

struct FSkylineTorPulseEventHandlerOnImpactData
{
	UPROPERTY()
	FHitResult Hit;

	FSkylineTorPulseEventHandlerOnImpactData(FHitResult _Hit)
	{
		Hit = _Hit;
	}
}