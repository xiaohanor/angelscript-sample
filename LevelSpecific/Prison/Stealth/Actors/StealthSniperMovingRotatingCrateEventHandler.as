UCLASS(Abstract)

class UStealthSniperMovingRotatingCrateEventHandler : UHazeEffectEventHandler
{
	AStealthSniperMovingRotatingCrate MovingRotatingCrate;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MovingRotatingCrate = Cast<AStealthSniperMovingRotatingCrate>(Owner);
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
	void StartRotation()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopRotation()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ResetRotation()
    {
	}
}