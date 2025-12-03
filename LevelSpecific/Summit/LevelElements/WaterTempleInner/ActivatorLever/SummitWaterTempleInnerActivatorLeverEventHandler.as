UCLASS(Abstract)
class USummitWaterTempleInnerActivatorLeverEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActivationStarted(FSummitWaterTempleInnerActivatorLeverActivateParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActivationFinished() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnResetStarted(FSummitWaterTempleInnerActivatorLeverActivateParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnResetFinished() {}
};