UCLASS(Abstract)
class UMagnetDroneMovingPlatformEventHandler : UHazeEffectEventHandler
{
	AMagnetDroneMovingPlatform Platform;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Platform = Cast<AMagnetDroneMovingPlatform>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartMoving()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopMoving()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ChangeDirection()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ReachedStart()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ReachedEnd()
    {
	}
};