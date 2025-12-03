UCLASS(Abstract)
class UMeltdownBossPhaseTwoSpaceBomberEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpaceBomberPhaseStart() {}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpaceBomberPhaseEnd() {}
};