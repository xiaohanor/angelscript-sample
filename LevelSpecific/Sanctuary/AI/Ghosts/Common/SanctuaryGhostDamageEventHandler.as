UCLASS(Abstract)
class USanctuaryGhostCommonEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeath()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLightDamageStart()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLightDamageStop()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDodge()
	{
	}
}