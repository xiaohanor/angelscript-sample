UCLASS(Abstract)
class UTundraRiverBoulder_DestructibleObject_EffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Break()
	{
	}
};