UCLASS(Abstract)
class UHackableSpinningFanEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	AHackableSpinningFan SpinningFan;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SpinningFan = Cast<AHackableSpinningFan>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartSpinningFan() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void SpinDirectionReversed() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StopSpinningFan() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlayerStartedSpinning() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PlayerStoppedSpinning() { }

}