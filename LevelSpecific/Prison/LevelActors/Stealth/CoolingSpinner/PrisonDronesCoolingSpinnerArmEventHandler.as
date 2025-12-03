UCLASS(Abstract)
class UPrisonDronesCoolingSpinnerArmEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotEditable, BlueprintReadOnly)
	APrisonDronesCoolingSpinnerArm SpinnerArm;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SpinnerArm = Cast<APrisonDronesCoolingSpinnerArm>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartRetract()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void EndRetract()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartExtend()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void EndExtend()
	{
	}
};