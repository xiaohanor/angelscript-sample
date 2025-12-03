struct FSummitTailCatapultBasketOnReleaseParams
{
	UPROPERTY()
	float PulledBackPercent;
}

UCLASS(Abstract)
class USummitTailCatapultBasketEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRetractStart()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRelease(FSummitTailCatapultBasketOnReleaseParams Params)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnResetStart()
	{

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnResetEnd()
	{
		
	}
};