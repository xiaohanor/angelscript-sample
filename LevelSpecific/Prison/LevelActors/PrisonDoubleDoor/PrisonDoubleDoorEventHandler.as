UCLASS(Abstract)
class UPrisonDoubleDoorEventHandler : UHazeEffectEventHandler
{
	APrisonDoubleDoor DoubleDoor;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DoubleDoor = Cast<APrisonDoubleDoor>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartOpen()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Opened()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartClose()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void Closed()
    {
	}
};