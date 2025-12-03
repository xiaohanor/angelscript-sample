
UCLASS(Abstract)
class UWorld_Prison_InBetween_Interactable_HackableCraneArm_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void ArmVerticalChangeDirection(){}

	UFUNCTION(BlueprintEvent)
	void ArmHorizontalChangeDirection(){}

	UFUNCTION(BlueprintEvent)
	void BaseChangeDirection(){}

	UFUNCTION(BlueprintEvent)
	void BaseStopMoving(){}

	UFUNCTION(BlueprintEvent)
	void BaseStartMoving(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(NotEditable)
	USwarmDroneHijackTargetableComponent SwarmHackingComp;
	
	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		SwarmHackingComp = USwarmDroneHijackTargetableComponent::Get(HazeOwner);

	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return SwarmHackingComp.IsHijacked();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !SwarmHackingComp.IsHijacked();
	}

}