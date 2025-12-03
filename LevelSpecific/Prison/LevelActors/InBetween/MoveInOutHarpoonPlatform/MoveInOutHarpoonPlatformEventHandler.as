UCLASS(Abstract)
class UMoveInOutHarpoonPlatformEventHandler : UHazeEffectEventHandler
{
	AMoveInOutHarpoonPlatform Platform;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Platform = Cast<AMoveInOutHarpoonPlatform>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartMovingOut()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopAtOutLocation()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartMovingIn()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopAtInLocation()
    {
	}
};