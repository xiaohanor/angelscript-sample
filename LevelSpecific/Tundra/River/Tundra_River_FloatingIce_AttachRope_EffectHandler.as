UCLASS(Abstract)
class UTundra_River_FloatingIce_AttachRope_EffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TetherRemoved()
	{
	}
};