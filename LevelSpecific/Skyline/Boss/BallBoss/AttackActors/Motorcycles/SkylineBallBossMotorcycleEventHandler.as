
struct FSkylineBallBossMotorcycleImpactPlayerEventHandlerParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

class USkylineBallBossMotorcycleEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AppearStart() 
	{
		// PrintToScreen("AppearStart", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AppearEnd() 
	{
		// PrintToScreen("AppearEnd", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Disappear() 
	{
		// PrintToScreen("Disappear", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Revving() 
	{
		// PrintToScreen("Revving", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Thrown() 
	{
		// PrintToScreen("Thrown", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGround() 
	{
		// PrintToScreen("OnGround", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ImpactPlayer(FSkylineBallBossMotorcycleImpactPlayerEventHandlerParams Params) 
	{
		// PrintToScreen("ImpactPlayer", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GoingOffEdge() 
	{
		// PrintToScreen("GoingOffEdge", 5.0);
	}
}