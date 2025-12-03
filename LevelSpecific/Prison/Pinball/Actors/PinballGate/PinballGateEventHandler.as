struct FPinballGateOnLockBrokenEventData
{
	APinballBreakableLock BreakableLock;
};

UCLASS(Abstract)
class UPinballGateEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	APinballGate Gate;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Gate = Cast<APinballGate>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLockBroken(FPinballGateOnLockBrokenEventData EventData) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOpen() {}
};