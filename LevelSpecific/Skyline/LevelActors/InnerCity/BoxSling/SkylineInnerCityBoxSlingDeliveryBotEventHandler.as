struct FSkylineInnerCityBoxSlingDeliveryBotEventTriggers
{
	bool bTriggeredStart = false;
	bool bTriggeredDropStart = false;
	bool bTriggeredDropStop = false;
	bool bTriggeredRetractStart = false;
	bool bTriggeredRetractStop = false;
	bool bTriggeredStop = false;
}

UCLASS(Abstract)
class USkylineInnerCityBoxSlingDeliveryBotEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeliveryBotStart() 
	{
		//PrintToScreen("Success OnDeliveryBotStart", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeliveryDropStart() 
	{
		//PrintToScreen("Success OnDeliveryDropStart", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeliveryDropStop() 
	{
		//PrintToScreen("Success OnDeliveryDropStop", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeliveryRetractStart() 
	{
		//PrintToScreen("Success OnDeliveryRetractStart", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeliveryRetractStop() 
	{
		//PrintToScreen("Success OnDeliveryRetractStop", 5.0);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeliveryBotStop() 
	{
		//PrintToScreen("Success OnDeliveryBotStop", 5.0);
	}
}