event void FDanceShowdownShowCrowdActorsEvent();
event void FDanceShowdownHideCrowdActorsEvent();
event void FDanceShowdownSetCrowdIdleEvent(bool bIdle);

enum ECrowdMonkeyState
{
	Idle,
	Dancing,
	Angry,
	Cheer
}
class UDanceShowdownCrowdMonkeyManager : UActorComponent
{
	FDanceShowdownShowCrowdActorsEvent ShowCrowdActorsEvent;
	FDanceShowdownShowCrowdActorsEvent ShowStageCrowdActorsEvent;
	FDanceShowdownHideCrowdActorsEvent HideCrowdActorsEvent;
	FDanceShowdownHideCrowdActorsEvent HideStageCrowdActorsEvent;
	FDanceShowdownSetCrowdIdleEvent SetMonkeysIdleEvent;

	UPROPERTY()
	ECrowdMonkeyState CurrentCrowdState = ECrowdMonkeyState::Idle;

	UFUNCTION(BlueprintCallable)
	void ShowAllCrowdActors()
	{
		ShowCrowdActorsEvent.Broadcast();
	}

	UFUNCTION(BlueprintCallable)
	void ShowAllStageCrowdActors()
	{
		ShowStageCrowdActorsEvent.Broadcast();
	}

	UFUNCTION(BlueprintCallable)
	void HideAllStageCrowdActors()
	{
		HideStageCrowdActorsEvent.Broadcast();
	}

	UFUNCTION(BlueprintCallable)
	void HideAllCrowdActors()
	{
		HideCrowdActorsEvent.Broadcast();
	}

	UFUNCTION(BlueprintCallable)
	void SetMonkeysIdle(bool bIdle)
	{
		SetMonkeysIdleEvent.Broadcast(bIdle);
	}

	UFUNCTION(BlueprintCallable)
	void SetMonkeysState(ECrowdMonkeyState NewState)
	{
		CurrentCrowdState = NewState;
	}
};