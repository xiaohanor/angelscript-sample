UCLASS(Abstract)
class UGravityBikeBladeTargetWidget : UHazeUserWidget
{
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation In;
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation Activate;

	UGravityBikeBladePlayerComponent BladeComp;
	private bool bPlayedRemoveAnimation = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		BladeComp = UGravityBikeBladePlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnAdded()
	{
		PlayAnimation(In);
		bPlayedRemoveAnimation = false;
	}

	UFUNCTION(BlueprintOverride)
	void RemoveFromScreen()
	{
		PlayAnimation(Activate);
	}

	UFUNCTION(BlueprintOverride)
	void OnAnimationFinished(const UWidgetAnimation Animation)
	{
		if (Animation == Activate)
			FinishRemovingWidget();
	}
};