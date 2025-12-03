UCLASS(Abstract)
class USkylineBallBossAttachedDetonatorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSpawned() 
	{
		// PrintToScreen("OnSpawned", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDetached() 
	{
		// PrintToScreen("OnDetached", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEvaporateDisintegrate() 
	{
		// PrintToScreen("OnEvaporateDisintegrate", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBladeHit() 
	{
		// PrintToScreen("OnBladeHit", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDetonate() 
	{
		// PrintToScreen("OnDetonate", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBossBlinkImpact() 
	{
		// PrintToScreen("OnBossBlinkImpact", 5.0);
	}
}