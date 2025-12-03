
UCLASS(Abstract)
class UTundra_IcePalace_KeyHole_LockPuzzle_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnKeyPinTimeRanOut(FKeyHolePinParams KeyHolePinParams){}

	UFUNCTION(BlueprintEvent)
	void OnKeyPinPuchedInPlace(FKeyHolePinParams KeyHolePinParams){}

	UFUNCTION(BlueprintEvent)
	void OnKeyPinInteractedWith(FKeyHolePinParams KeyHolePinParams){}

	UFUNCTION(BlueprintEvent)
	void OnKeyPinWiggle(FKeyHolePinParams KeyHolePinParams){}

	UFUNCTION(BlueprintEvent)
	void OnKeyPinReveal(FKeyHolePinParams KeyHolePinParams){}

	UFUNCTION(BlueprintEvent)
	void OnLeverTicking(FKeyHoleLeverParams KeyHoleLeverParams){}

	UFUNCTION(BlueprintEvent)
	void OnLeverStopped(FKeyHoleLeverParams KeyHoleLeverParams){}

	UFUNCTION(BlueprintEvent)
	void OnLeverPulled(FKeyHoleLeverParams KeyHoleLeverParams){}

	/* END OF AUTO-GENERATED CODE */

}