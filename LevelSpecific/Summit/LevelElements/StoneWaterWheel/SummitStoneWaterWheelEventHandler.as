struct FSummitStoneWaterWheelOnSmashedThroughGateParams
{
	UPROPERTY()
	AHazeActor Gate;
}

UCLASS(Abstract)
class USummitStoneWaterWheelEventHandler : UHazeEffectEventHandler
{
	ASummitStoneWaterWheel Wheel;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Wheel = Cast<ASummitStoneWaterWheel>(Owner);
	}

	// When sword is melted and it starts to fall
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWheelActivated()
	{
	}

	// When it lands for the first time
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLanded()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashedThroughGate(FSummitStoneWaterWheelOnSmashedThroughGateParams Params)
	{
	}


	UFUNCTION(BlueprintPure)
	float CurrentMoveSpeed()
	{
		return Wheel.MoveComp.Velocity.Size();
	}
};