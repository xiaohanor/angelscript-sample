
UCLASS(Abstract)
class UVO_Prison_DroneSeesaw_BalanceActEfforts_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY()
	UHazeMovementComponent MovementComp;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		MovementComp = UHazeMovementComponent::Get(HazeOwner);
	}


	UFUNCTION(BlueprintPure)
	bool IsOnSlidingGround()
	{
		return MovementComp.IsOnSlidingGround();
	}


	
}

