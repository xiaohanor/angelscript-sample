
UCLASS(Abstract)
class UVO_Skyline_Nightclub_Lanterns_Trashcan_SoundDef : UVO_SideContent_AroundCombat_SoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void SkylineVendingMachine_SpawnedCan(){}

	UFUNCTION(BlueprintEvent)
	void SkylineVendingMachine_VendingMachineBroken(){}

	UFUNCTION(BlueprintEvent)
	void SkylineVendingMachine_HitByKatana(){}

	UFUNCTION(BlueprintEvent)
	void SkylineTrashCan_TrashCanStopSpinning(){}

	UFUNCTION(BlueprintEvent)
	void SkylineTrashCan_SlingableEnterTrashCan(){}

	UFUNCTION(BlueprintEvent)
	void SkylineTrashCan_HitByKatana(){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintPure)
	int32 GetCanCount() const
	{
		return TListedActors<ASkylineThrowableTrash>().GetArray().Num();
	}

	UFUNCTION(BlueprintOverride)
	void DebugTick(float DeltaSeconds)
	{
		PrintToScreen("Num: " + GetCanCount());
	}
}