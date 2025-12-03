
UCLASS(Abstract)
class UCharacter_Boss_Prison_DarkMio_TakeControl_POV_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void TakeControlExit(){}

	UFUNCTION(BlueprintEvent)
	void TakeControlHitBoss(){}

	UFUNCTION(BlueprintEvent)
	void TakeControlThrow(){}

	UFUNCTION(BlueprintEvent)
	void TakeControlPull(){}

	UFUNCTION(BlueprintEvent)
	void TakeControlEnter(){}

	/* END OF AUTO-GENERATED CODE */

	APrisonBoss Boss;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Boss = Cast<APrisonBoss>(HazeOwner);
	}

	UFUNCTION(BlueprintPure)
	bool IsBossControlled() const
	{
		return Boss.bControlled;
	}
}