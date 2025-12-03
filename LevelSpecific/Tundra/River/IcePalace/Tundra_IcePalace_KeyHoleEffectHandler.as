UCLASS(Abstract)
class UTundra_IcePalace_KeyHoleEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLeverPulled(FKeyHoleLeverParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLeverStopped(FKeyHoleLeverParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLeverStoppedWithStartingKeyPinOrder(FKeyHoleLeverParams Params) {}

	//If all of the pins are in the correct order but no symbols have been interacted with on Mios side,we play hint VO
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPinsInRightOrderNoSymbolsPunchedIn() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLeverTicking(FKeyHoleLeverParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnKeyPinReveal(FKeyHolePinParams Params) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnKeyPinWiggle(FKeyHolePinParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnKeyPinInteractedWith(FKeyHolePinParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnKeyPinPuchedInPlace(FKeyHolePinParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnKeyPinTimeRanOut(FKeyHolePinParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCrumbRaisePins() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnKeySymbolPunchedInPlace(FKeyHoleSymbolParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnKeySymbolPunchedIncorrectPosition(FKeyHoleSymbolParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnKeySymbolFrameMoved(FKeyHoleFrameParams Params) {}
};

struct FKeyHoleLeverParams
{
	UPROPERTY()
	ATundra_IcePalace_InsideLockLever Lever;
}

struct FKeyHolePinParams
{
	UPROPERTY()
	ATundra_IcePalace_RotatingKeyPin RotatingKeyPin;
}

struct FKeyHoleSymbolParams
{
	UPROPERTY()
	ATundra_IcePalace_KeySymbol KeySymbol;
}

struct FKeyHoleFrameParams
{
	UPROPERTY()
	ATundra_IcePalace_KeySymbol KeySymbol;
	UPROPERTY()
	bool bRotatedToCorrectPlace;
}