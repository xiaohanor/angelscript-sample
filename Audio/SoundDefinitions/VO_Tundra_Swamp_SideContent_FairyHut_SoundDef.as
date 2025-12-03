
UCLASS(Abstract)
class UVO_Tundra_Swamp_SideContent_FairyHut_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void DoorOpen(){}

	UFUNCTION(BlueprintEvent)
	void DoorClose(){}

	UFUNCTION(BlueprintEvent)
	void MonkeySlamHut(){}

	UFUNCTION(BlueprintEvent)
	void FirePlaceOn(){}

	UFUNCTION(BlueprintEvent)
	void FirePlaceOff(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditInstanceOnly)
	AFairyHut FairyHut;
	
	UPROPERTY(EditInstanceOnly)
	AFairyHutFireplace FairyHutFireplace;

	UPROPERTY(EditInstanceOnly)
	APlayerLookAtTrigger LookAtTrigger;
}