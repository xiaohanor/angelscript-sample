
UCLASS(Abstract)
class UVO_Summit_PlayerInWater_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPlayerSwimmingComponent SwimComp;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		SwimComp = UPlayerSwimmingComponent::Get(PlayerOwner);
	}


	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Is Swimming"))
	bool IsSwimming() const
	{
		return SwimComp.IsSwimming();
	}

}