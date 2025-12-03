
class UStickSpinWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FStickSpinSettings SpinSettings;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsSimplified = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FStickSpinState SpinState;

	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation ShowAnim;
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation HideAnim;

	UFUNCTION(BlueprintOverride)
	void OnAdded()
	{
		PlayAnimation(ShowAnim);
	}

	UFUNCTION(BlueprintOverride)
	void RemoveFromScreen()
	{
		PlayAnimation(HideAnim);
	}

	UFUNCTION(BlueprintOverride)
	void OnAnimationFinished(const UWidgetAnimation Animation)
	{
		if (Animation == HideAnim && bIsInDelayedRemove)
			FinishRemovingWidget();
	}

	void Start()
	{
		BP_UpdateSettings();
	}

	UFUNCTION(BlueprintEvent)
	void BP_UpdateSettings() {}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
	}
};