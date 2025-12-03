UCLASS(Abstract)
class UPinballBreakableLockEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	APinballBreakableLock BreakableLock;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BreakableLock = Cast<APinballBreakableLock>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBroken() {}
};