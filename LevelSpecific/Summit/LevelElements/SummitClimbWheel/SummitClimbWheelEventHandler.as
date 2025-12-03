UCLASS(Abstract)
class USummitClimbWheelEventHandler : UHazeEffectEventHandler
{
	ASummitClimbWheel Wheel;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Wheel = Cast<ASummitClimbWheel>(Owner);
	}

	/** Gets rotation speed in radians (0 -> 0.5 ish in this actor) */
	UFUNCTION(BlueprintPure, Meta = (AutoCreateBPNode))
	float GetRotationSpeed() 
	{
		return Wheel.RotateRoot.Velocity;
	}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartedMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStoppedMoving() {}
};