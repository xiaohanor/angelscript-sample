UCLASS(Abstract)
class UHackableCraneArmEventHandler : UHazeEffectEventHandler
{
	AHackableCraneArm CraneArm;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CraneArm = Cast<AHackableCraneArm>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BaseStartMoving()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BaseStopMoving()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BaseChangeDirection()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ArmStartMoving()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ArmStopMoving()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ArmHorizontalChangeDirection()
    {
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ArmVerticalChangeDirection()
    {
	}

};