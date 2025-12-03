
UCLASS(Abstract)
class UVO_Tundra_IcePalace_KeyHole_LockPuzzle_SoundDef : UHazeVOSoundDef
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

	UFUNCTION(BlueprintEvent)
	void OnLeverStoppedWithStartingKeyPinOrder(FKeyHoleLeverParams KeyHoleLeverParams){}

	UFUNCTION(BlueprintEvent)
	void OnPinsInRightOrderNoSymbolsPunchedIn(){}

	UFUNCTION(BlueprintEvent)
	void OnCrumbRaisePins(){}

	UFUNCTION(BlueprintEvent)
	void OnKeySymbolPunchedInPlace(FKeyHoleSymbolParams KeyHoleSymbolParams){}

	UFUNCTION(BlueprintEvent)
	void OnKeySymbolPunchedIncorrectPosition(FKeyHoleSymbolParams KeyHoleSymbolParams){}

	UFUNCTION(BlueprintEvent)
	void OnKeySymbolFrameMoved(FKeyHoleFrameParams KeyHoleFrameParams){}

	/* END OF AUTO-GENERATED CODE */

}