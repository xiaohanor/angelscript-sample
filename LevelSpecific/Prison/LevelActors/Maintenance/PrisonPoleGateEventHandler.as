UCLASS(Abstract)
class UPrisonPoleGateEventHandler : UHazeEffectEventHandler
{

	APrisonPoleGate Gate;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Gate = Cast<APrisonPoleGate>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LightOnLeft()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LightOnRight()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LightOffLeft()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LightOffRight()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LightGreen()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GateStartMove()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void GateReachTop()
	{
	}

};