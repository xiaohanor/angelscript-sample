
UCLASS(Abstract)
class UVO_Island_Tower_SideContent_PaddleTargets_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnSpinStart(){}

	UFUNCTION(BlueprintEvent)
	void OnSpinStop(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY()
	int Hits = 0;

	int HitsRequired = 0;

	UFUNCTION()
	bool IncrementAndReturnIfToTrigger()
	{
		++Hits;
		if (Hits >= HitsRequired)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		HitsRequired = Math::RandRange(2, 5);
	}

}