
UCLASS(Abstract)
class UVO_Centipede_WaterPlug_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnDestroyed(){}

	UFUNCTION(BlueprintEvent)
	void OnUnplug(FCentipedeWaterPlugEventData CentipedeWaterPlugEventData){}

	UFUNCTION(BlueprintEvent)
	void OnStopPulling(FCentipedeWaterPlugEventData CentipedeWaterPlugEventData){}

	UFUNCTION(BlueprintEvent)
	void OnStartPulling(FCentipedeWaterPlugEventData CentipedeWaterPlugEventData){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerDetach(FCentipedeWaterPlugEventData CentipedeWaterPlugEventData){}

	UFUNCTION(BlueprintEvent)
	void OnPlayerAttached(FCentipedeWaterPlugEventData CentipedeWaterPlugEventData){}

	/* END OF AUTO-GENERATED CODE */

}