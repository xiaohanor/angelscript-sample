UCLASS(Abstract)
class USpaceWalkHookTargetWidget : UTargetableWidget
{
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
}