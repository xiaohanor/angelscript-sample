UCLASS(Abstract)
class UHackableLiftEventHandler : UHazeEffectEventHandler
{
	AHackableLift HackableLift;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HackableLift = Cast<AHackableLift>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Activated()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Deactivated()
    {
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
	void EnteredCameraVolume()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ExitedCameraVolume()
    {
	}
};