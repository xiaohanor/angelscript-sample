struct FSummitCatapultLauncherStatueOnImpactedByCartParams
{
	UPROPERTY()
	FVector ImpactLocation;
}

UCLASS(Abstract)
class USummitCatapultLauncherStatueEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHandsLowered() {TEMPORAL_LOG(Owner).Event("Lowered");}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHandsRaised() {TEMPORAL_LOG(Owner).Event("Raised");}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHandsImpactedByCart(FSummitCatapultLauncherStatueOnImpactedByCartParams Params) {TEMPORAL_LOG(Owner).Event("Impacted");}
};