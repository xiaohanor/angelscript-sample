UCLASS(Abstract)
class UMeltdownBossPhaseTwoSpaceShipsEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpaceShipsPhaseStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpaceShipsPhaseEnd() {}
};