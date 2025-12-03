
UCLASS(Abstract)
class UWorld_Sanctuary_Below_Event_Sweetener_Waterfall_Lightworm_Overlap_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */
	UFUNCTION(BlueprintOverride)
    bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
                                        FName& BoneName, bool& bUseAttach)
    {
        ComponentName = n"Head";
		TargetActor = HazeOwner;
		return true;
    }
}
