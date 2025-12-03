UCLASS(Abstract)
class UMeltdownBossPhaseTwoSpaceBatEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpaceBatPhaseStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpaceBatSwingLeft() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpaceBatSwingRight() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpaceBatPhaseEnd() {}
};