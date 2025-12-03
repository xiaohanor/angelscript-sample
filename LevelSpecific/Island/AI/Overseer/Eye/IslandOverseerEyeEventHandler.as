UCLASS(Abstract)
class UIslandOverseerEyeEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChargeTelegraphStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChargeTelegraphStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFlybyTelegraphStop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEnterStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEnterEnd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExitStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExitEnd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChargeBounce(FIslandOverseerEyeEventHandlerOnChargeBounceData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWallContact() {}
}

struct FIslandOverseerEyeEventHandlerOnChargeBounceData
{
	UPROPERTY()
	FVector ImpactLocation;

	UPROPERTY()
	FVector ImpactNormal;

	FIslandOverseerEyeEventHandlerOnChargeBounceData(FVector InImpactLocation, FVector InImpactNormal)
	{
		ImpactLocation = InImpactLocation;
		ImpactNormal = InImpactNormal;
	}
}