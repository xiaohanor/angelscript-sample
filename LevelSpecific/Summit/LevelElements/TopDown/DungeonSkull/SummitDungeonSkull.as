class ASummitDungeonSkull : AHazeActor
{
	UFUNCTION(BlueprintCallable)
	void OnStartedOpening()
	{
		USummitDungeonSkullEventHandler::Trigger_OnStartedOpening(this);
	}

	UFUNCTION(BlueprintCallable)
	void OnStoppedOpening()
	{
		USummitDungeonSkullEventHandler::Trigger_OnStoppedOpening(this);
	}

	UFUNCTION(BlueprintCallable)
	void OnStartedClosing()
	{
		USummitDungeonSkullEventHandler::Trigger_OnStartedClosing(this);
	}

	UFUNCTION(BlueprintCallable)
	void OnStoppedClosing()
	{
		USummitDungeonSkullEventHandler::Trigger_OnStoppedClosing(this);
	}
};