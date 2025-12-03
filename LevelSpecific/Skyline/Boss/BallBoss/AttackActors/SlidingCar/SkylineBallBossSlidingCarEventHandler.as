class USkylineBallBossSlidingCarEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AppearStart() 
	{
		//PrintToScreen("AppearStart", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void AppearEnd() 
	{
		//PrintToScreen("AppearEnd", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Disappear() 
	{
		//PrintToScreen("Disappear", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Thrown()
	{
		//PrintToScreen("Thrown", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ImpactGround()
	{
		//PrintToScreen("ImpactGround", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartFalling()
	{
		//PrintToScreen("ImpactGround", 5.0);
	}
}