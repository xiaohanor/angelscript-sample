
UCLASS(Abstract)
class UVO_MoonMarket_MoonMarketCat_Entrance_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnCatStartCollecting(FMoonMarketInteractingPlayerEventParams MoonMarketInteractingPlayerEventParams){}

	UFUNCTION(BlueprintEvent)
	void OnCatCollected(FMoonMarketInteractingPlayerEventParams MoonMarketInteractingPlayerEventParams){}

	UFUNCTION(BlueprintEvent)
	void OnCatTotalUpdated(FMoonMarketCatEventParams MoonMarketCatEventParams){}

	UFUNCTION(BlueprintEvent)
	void OnStartFloatingToGate(){}

	UFUNCTION(BlueprintEvent)
	void OnMimicLidOpen(){}

	UFUNCTION(BlueprintEvent)
	void OnMimicLidClosed(){}

	/* END OF AUTO-GENERATED CODE */

}