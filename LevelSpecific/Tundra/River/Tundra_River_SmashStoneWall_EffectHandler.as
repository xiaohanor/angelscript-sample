UCLASS(Abstract)
class UTundra_River_SmashStoneWall_EffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FailedGroundSlam()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SuccessfulGroundSlam()
	{
	}
};