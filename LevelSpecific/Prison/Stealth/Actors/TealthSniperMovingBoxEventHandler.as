UCLASS(Abstract)

class UStealthSniperMovingBoxEventHandler : UHazeEffectEventHandler
{
	AStealthSniperMovingCrate MovingBox;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MovingBox = Cast<AStealthSniperMovingCrate>(Owner);
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