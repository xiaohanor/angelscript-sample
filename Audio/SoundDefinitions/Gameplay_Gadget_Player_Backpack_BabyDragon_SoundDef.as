
UCLASS(Abstract)
class UGameplay_Gadget_Player_Backpack_BabyDragon_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		DefaultEmitter.SetPlayerPanning(PlayerOwner);
	}

}