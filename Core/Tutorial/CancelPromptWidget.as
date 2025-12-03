
class UCancelPromptWidget : UHazeUserWidget
{
	UPROPERTY()
	FText DefaultCancelText;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FText CancelText;

	UPROPERTY(BlueprintReadOnly)
	bool bIsAllowedToCancel = true;

	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation ShowAnim;
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation HideAnim;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
	}

	UFUNCTION(BlueprintEvent)
    void OnCancelPressed()
    {
    }

	UFUNCTION(BlueprintEvent)
	void Update()
	{
	}

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
};