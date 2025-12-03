struct FHackablePinballPaddleInputStartEventData
{
	/**
	 * How hard was the trigger pressed? (Approximately)
	 * Range is 0 -> 1
	 */
	UPROPERTY()
	float Intensity = 0.0;
}

UCLASS(Abstract)
class UHackablePinballEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPaddleInputStart(FHackablePinballPaddleInputStartEventData EventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPaddleInputStop()
	{
	}
};