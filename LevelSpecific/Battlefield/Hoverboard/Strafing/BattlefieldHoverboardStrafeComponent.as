class UBattlefieldHoverboardStrafeComponent : UActorComponent
{
	private bool bShouldStrafe = false;

	UFUNCTION(BlueprintCallable)
	void ToggleStrafing(bool bToggleOn)
	{
		bShouldStrafe = bToggleOn;
	}

	bool ShouldStrafe()
	{
		return bShouldStrafe;
	}
};