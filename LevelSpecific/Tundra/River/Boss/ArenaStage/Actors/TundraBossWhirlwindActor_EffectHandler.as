UCLASS(Abstract)
class UTundraBossWhirlwindActor_EffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWhirlwindStarted()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWhirlwindStopped()
	{
	}
};