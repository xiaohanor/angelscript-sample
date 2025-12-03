UCLASS(Abstract)
class USummitStoneBeastSlasherEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTakeDamage(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeath(){}
};