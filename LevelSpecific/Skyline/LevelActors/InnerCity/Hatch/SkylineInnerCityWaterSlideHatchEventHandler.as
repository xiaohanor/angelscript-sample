
struct FSkylineInnerCityWaterSlideHatchStuckWrongWayEventParams
{
	UPROPERTY()
	AHazePlayerCharacter TurningWrongPlayer;
};

UCLASS(Abstract)
class USkylineInnerCityWaterSlideHatchEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartTurning() 
	{
		//PrintToScreen("Success OnStartTurning", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopTurning() 
	{
		//PrintToScreen("Success OnStopTurning", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHatchComeOff() 
	{
		//PrintToScreen("Success OnHatchComeOff", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHatchStuckWrongWay(FSkylineInnerCityWaterSlideHatchStuckWrongWayEventParams Params) 
	{
		//PrintToScreen("Success OnHatchComeOff", 5.0);
	}
}