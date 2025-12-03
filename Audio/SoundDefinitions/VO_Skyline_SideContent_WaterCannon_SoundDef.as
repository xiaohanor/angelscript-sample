
UCLASS(Abstract)
class UVO_Skyline_SideContent_WaterCannon_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnStartSpray(){}

	UFUNCTION(BlueprintEvent)
	void OnStopSpray(){}

	UFUNCTION(BlueprintEvent)
	void OnMoveStartYaw(){}

	UFUNCTION(BlueprintEvent)
	void OnMoveStopYaw(){}

	UFUNCTION(BlueprintEvent)
	void OnMoveStartPitch(){}

	UFUNCTION(BlueprintEvent)
	void OnMoveStopPitch(){}

	UFUNCTION(BlueprintEvent)
	void OnConstrainHit(){}

	UFUNCTION(BlueprintEvent)
	void OnWaterSegmentBlocked(FInnerCityWaterCannonEventBlockedData InnerCityWaterCannonEventBlockedData){}

	UFUNCTION(BlueprintEvent)
	void OnWaterSegmentHitWater(FInnerCityWaterCannonEventHitWaterData InnerCityWaterCannonEventHitWaterData){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintPure)
	bool IsInteractingWithMio() const
	{
		AInnerCityWaterCannon WaterCannon = Cast<AInnerCityWaterCannon>(HazeOwner);
		if (WaterCannon != nullptr && WaterCannon.InteractingPlayer.IsMio())
			return true;

		return false;
	}
}