
UCLASS(Abstract)
class UVO_Prison_Stealth_SideContent_ClayPigeons_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void PrisonDrones_PigeonLauncher_OnLaunchPigeon(){}

	UFUNCTION(BlueprintEvent)
	void PrisonDrones_Pigeon_OnPigeonHit(){}

	UFUNCTION(BlueprintEvent)
	void MagnetDrone_AttractionStarted(FMagnetDroneAttractionStartedParams MagnetDroneAttractionStartedParams){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditInstanceOnly)
	AMagnetDroneSwitch SwitchClayLauncher;

	UMagnetDroneAttractionComponent AttractionComp;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		AttractionComp = UMagnetDroneAttractionComponent::Get(HazeOwner);
	}

	UFUNCTION(BlueprintPure)
	bool IsTargetingClayLauncher() const
	{
		if (AttractionComp.GetAttractionTarget().GetActor() == SwitchClayLauncher)
		{
			return true;
		}

		return false;
	}
}