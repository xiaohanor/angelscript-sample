UCLASS(Abstract)
class UIslandRedBlueAimCrosshairWidget : UCrosshairWithAutoAimWidget
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartLookingAtTarget(UIslandRedBlueTargetableComponent Target) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopLookingAtTarget(UIslandRedBlueTargetableComponent Target) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartLookingAtOverloadPanel(AIslandOverloadShootablePanel Panel) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopLookingAtOverloadPanel(AIslandOverloadShootablePanel Panel) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCompleteOverloadPanel(AIslandOverloadShootablePanel Panel) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartLookingAtForceField(bool bIsEnemy) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopLookingAtForceField(bool bIsEnemy) {}

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bOverheatBarVisible = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float OverheatAlpha = 0.0;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsOverheated = false;
}