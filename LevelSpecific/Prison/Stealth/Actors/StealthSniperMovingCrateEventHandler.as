UCLASS(Abstract)

class UStealthSniperMovingCrateEventHandler : UHazeEffectEventHandler
{
	AStealthSniperMovingCrate MovingCrate;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MovingCrate = Cast<AStealthSniperMovingCrate>(Owner);
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
}