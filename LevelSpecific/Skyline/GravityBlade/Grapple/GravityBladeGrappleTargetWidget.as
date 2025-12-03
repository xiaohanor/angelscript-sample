UCLASS(Abstract)
class UGravityBladeGrappleTargetWidget : UTargetableWidget
{
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation In;
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation Activate;

	private bool bPlayedRemoveAnimation = false;

	UFUNCTION(BlueprintOverride)
	void OnAdded()
	{
		PlayAnimation(In);
		bPlayedRemoveAnimation = false;
		RenderOpacity = 1.0;
	}

	UFUNCTION(BlueprintOverride)
	void BP_OnActivationAnimation()
	{
		Super::BP_OnActivationAnimation();

		PlayAnimation(Activate);
	}

	UFUNCTION(BlueprintOverride)
	void RemoveFromScreen()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnAnimationFinished(const UWidgetAnimation Animation)
	{
		if (bIsInDelayedRemove && Animation == Activate)
			FinishRemovingWidget();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (bIsInDelayedRemove && !IsAnimationPlaying(Activate))
		{
			SetRenderOpacity(Math::FInterpConstantTo(
				RenderOpacity, 0.0, InDeltaTime, 5.0
			));
			if (RenderOpacity <= 0.001)
				FinishRemovingWidget();
		}
	}
}