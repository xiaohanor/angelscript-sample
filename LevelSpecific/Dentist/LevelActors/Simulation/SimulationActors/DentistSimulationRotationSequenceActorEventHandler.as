/**
 * RotationSequenceActor moves through a sequence of rotations. Ball cannons are attached to this.
 */
UCLASS(Abstract)
class UDentistSimulationRotationSequenceActorEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	ADentistSimulationRotationSequenceActor RotationSequenceActor;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RotationSequenceActor = Cast<ADentistSimulationRotationSequenceActor>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMoving() {}
};