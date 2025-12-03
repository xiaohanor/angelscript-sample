struct FSummitBallistaOnCartRolledIntoParams
{
	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	float SpeedIntoCart;
}

struct FSummitBallistaOnCartHitHandsParams
{
	UPROPERTY()
	FVector HandImpactLocation;

	UPROPERTY()
	float CartSpeedAtImpact;
}

struct FSummitBallistaOnCartHitConstraintParams
{
	UPROPERTY()
	FVector CartLocation;

	UPROPERTY()
	float CartSpeedAtImpact;
}

UCLASS(Abstract)
class USummitBallistaEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCartRolledInto(FSummitBallistaOnCartRolledIntoParams Params) {TEMPORAL_LOG(Owner).Event("Rolled into");}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCartStartedMoving() {TEMPORAL_LOG(Owner).Event("Cart Started Moving");}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCartStoppedMoving() {TEMPORAL_LOG(Owner).Event("Stopped Moving");}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCartStartedLaunching() {TEMPORAL_LOG(Owner).Event("Started Launching");}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCartStoppedLaunching() {TEMPORAL_LOG(Owner).Event("Stopped Launching");}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCartStartedLowering() {TEMPORAL_LOG(Owner).Event("Started Lowering");}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCartStoppedLowering() {TEMPORAL_LOG(Owner).Event("Stopped Lowering");}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCartStartedRaising() {TEMPORAL_LOG(Owner).Event("Started Rising");}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCartStoppedRaising() {TEMPORAL_LOG(Owner).Event("Stopped Rising");}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCartImpactedHands(FSummitBallistaOnCartHitHandsParams Params) {TEMPORAL_LOG(Owner).Event("Cart Impacted Hands").Value("Impact Speed", Params.CartSpeedAtImpact);}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCartImpactedConstraint(FSummitBallistaOnCartHitConstraintParams Params) {TEMPORAL_LOG(Owner).Event("Cart Impacted Constraint").Value("Impact Speed", Params.CartSpeedAtImpact);}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDragonImpactSpinningBlocker() {TEMPORAL_LOG(Owner).Event("Hit Spinning Blocker");}
};