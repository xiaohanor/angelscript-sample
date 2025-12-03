
UCLASS(Abstract)
class UWorld_Island_Entrance_Event_ShipPassbys_KineticMovingActor_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	AKineticMovingActor MovingActor;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		MovingActor = Cast<AKineticMovingActor>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{

		return MovingActor.IsActive();	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !MovingActor.IsActive();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MovingActor.OnStartForward.AddUFunction(this, n"GoForward");
		MovingActor.OnReachedForward.AddUFunction(this, n"OnReachForward");
		MovingActor.OnStartBackward.AddUFunction(this, n"GoBackward");
		MovingActor.OnReachedBackward.AddUFunction(this, n"OnReachBackward");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MovingActor.OnStartForward.UnbindObject(this);
		MovingActor.OnStartBackward.UnbindObject(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{

	}

	UFUNCTION(BlueprintEvent)
	void GoForward() {}

	UFUNCTION(BlueprintEvent)
	void GoBackward() {}

	UFUNCTION(BlueprintEvent)
	void OnReachForward() {}

	UFUNCTION(BlueprintEvent)
	void OnReachBackward() {}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Moving Alpha"))
	float GetMovingAlpha() const
	{
		int ReachedForwardCount = 0;
		int ReachedBackwardCount = 0;

		return MovingActor.GetCurrentAlpha(ReachedForwardCount, ReachedBackwardCount);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Direction Value"))
	float GetDirectionSign() const
	{
		return MovingActor.IsMovingBackward() ? -1.0 : 1.0;
	}
}