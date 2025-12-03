
USTRUCT()
struct FCentipedeWaterPlugEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}

UCLASS(Abstract)
class UCentipedeWaterPlugEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerAttached(FCentipedeWaterPlugEventData Params) 
	{
		// DevPrintStringEvent("WaterPlug", "OnPlayerAttached " + Params.Player.GetName());
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerDetach(FCentipedeWaterPlugEventData Params) 
	{
		// DevPrintStringEvent("WaterPlug", "OnPlayerDetach " + Params.Player.GetName());
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartPulling(FCentipedeWaterPlugEventData Params) 
	{
		// DevPrintStringEvent("WaterPlug", "OnStartPulling " + Params.Player.GetName());
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopPulling(FCentipedeWaterPlugEventData Params) 
	{
		// DevPrintStringEvent("WaterPlug", "OnStopPulling " + Params.Player.GetName());
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnUnplug(FCentipedeWaterPlugEventData Params) 
	{
		// DevPrintStringEvent("WaterPlug", "OnUnplug " + Params.Player.GetName());
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnIshStopMoving() 
	{
		// DevPrintStringEvent("WaterPlug", "OnIshStopMoving ");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDestroyed() 
	{
		// DevPrintStringEvent("WaterPlug", "OnDestroyed");
	}
};