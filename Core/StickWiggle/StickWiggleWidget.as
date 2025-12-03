UCLASS(Abstract)
class UStickWiggleWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FStickWiggleSettings WiggleSettings;

	UPROPERTY(BindWidget)
	UImage InnerCircle;
	UPROPERTY(BindWidget)
	UImage ProgressCircle;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsSimplified = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FStickWiggleState WiggleState;

	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation ShowAnim;
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation HideAnim;

	UPROPERTY()
	UTexture2D MioProgressTexture;
	UPROPERTY()
	UTexture2D ZoeProgressTexture;

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
		if (WiggleSettings.bShowProgressBar)
		{
			InnerCircle.Visibility = ESlateVisibility::HitTestInvisible;
			ProgressCircle.Visibility = ESlateVisibility::HitTestInvisible;

			auto ProgressMat = ProgressCircle.GetDynamicMaterial();
			ProgressMat.SetScalarParameterValue(n"EndPercentage", WiggleState.WiggledAlpha);

			if (Player != nullptr && Player.IsMio())
				ProgressMat.SetTextureParameterValue(n"Texture", MioProgressTexture);
			else
				ProgressMat.SetTextureParameterValue(n"Texture", ZoeProgressTexture);

		}
		else
		{
			InnerCircle.Visibility = ESlateVisibility::Hidden;
			ProgressCircle.Visibility = ESlateVisibility::Hidden;
		}
	}
};