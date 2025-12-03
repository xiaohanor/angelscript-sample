
UCLASS(Abstract)
class UVO_Sandfish_Thumpers_MULTI_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnThumpSuccess(){}

	UFUNCTION(BlueprintEvent)
	void OnThumpFail(){}

	UFUNCTION(BlueprintEvent)
	void OnFullyDown(){}

	UFUNCTION(BlueprintEvent)
	void OnFullyReset(){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerAttached(){}

	UFUNCTION(BlueprintEvent)
	void SandSharkPlayer_OnBecameHunted(FSandSharkHuntedParams SandSharkHuntedParams){}

	UFUNCTION(BlueprintEvent)
	void SandSharkPlayer_OnStoppedBeingHunted(FSandSharkHuntedParams SandSharkHuntedParams){}

	/* END OF AUTO-GENERATED CODE */

}