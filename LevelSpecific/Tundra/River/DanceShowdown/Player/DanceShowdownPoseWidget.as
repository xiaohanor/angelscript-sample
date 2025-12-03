UCLASS(Abstract)
class UDanceShowdownWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly)
	UDanceShowdownPlayerComponent DanceShowdownComp;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		DanceShowdown::GetManager().OnGameEndedEvent.AddUFunction(this, n"HideWidget");
		DanceShowdown::GetManager().RhythmManager.OnNewStageEvent.AddUFunction(this, n"OnNewStage");
		DanceShowdown::GetManager().RhythmManager.OnGameResumeEvent.AddUFunction(this, n"ShowWidget");
	}


	UFUNCTION(BlueprintEvent)
	void ConfigureWidgetMio(){}

	UFUNCTION(BlueprintEvent)
	void ConfigureWidgetZoe(){}

	UFUNCTION(BlueprintEvent)
	void OnFailed(){}

	UFUNCTION(BlueprintEvent)
	void OnSucceeded(){}

	UFUNCTION(BlueprintEvent)
	void HideTutorial(){}

	UFUNCTION(BlueprintEvent)
	void HideWidget(){}

	UFUNCTION(BlueprintEvent)
	void ShowWidget(){}

	UFUNCTION(BlueprintEvent)
	void UpdateControllerPosition(float X, float Y){}

	UFUNCTION()
	private void OnNewStage(FDanceShowdownOnNewStageEventData Data)
	{
		HideWidget();
	}

	UFUNCTION(BlueprintEvent)
	void ShowUI()
	{
	}

	UFUNCTION(BlueprintEvent)
	void HideUI()
	{
	}
}