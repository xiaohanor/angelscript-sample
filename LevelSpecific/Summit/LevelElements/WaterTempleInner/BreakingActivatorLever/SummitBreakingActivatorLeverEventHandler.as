UCLASS(Abstract)
class USummitWaterTempleInnerBreakingActivatorLeverEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActivationStarted(FSummitWaterTempleInnerActivatorLeverActivateParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLeverBroken() {}
};