
class UButtonMashWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FButtonMashSettings MashSettings;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float MashProgress = 0.0;

	UPROPERTY(BindWidget)
	UInputButtonWidget InputButton;
	UPROPERTY(BindWidget)
	UImage InnerCircle;
	UPROPERTY(BindWidget)
	UImage ProgressCircle;

	UPROPERTY(BindWidget)
	UWidget ButtonMashIndicator;

	UPROPERTY(BindWidget)
	UWidget HoldIndicator;

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

	UFUNCTION(BlueprintEvent)
	void BP_Pulse() {}

	void Pulse()
	{
		BP_Pulse();
	}

	void Start()
	{
	}

	bool IsFaceButton() const
	{
		if (InputButton.DisplayedKey == EKeys::Gamepad_FaceButton_Left)
			return true;
		if (InputButton.DisplayedKey == EKeys::Gamepad_FaceButton_Right)
			return true;
		if (InputButton.DisplayedKey == EKeys::Gamepad_FaceButton_Top)
			return true;
		if (InputButton.DisplayedKey == EKeys::Gamepad_FaceButton_Bottom)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (MashSettings.ShouldShowProgress(Player))
		{
			InnerCircle.Visibility = ESlateVisibility::HitTestInvisible;
			ProgressCircle.Visibility = ESlateVisibility::HitTestInvisible;

			auto ProgressMat = ProgressCircle.GetDynamicMaterial();
			ProgressMat.SetScalarParameterValue(n"EndPercentage", MashProgress);

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

		if (IsFaceButton())
		{
			InnerCircle.RenderScale = FVector2D(1.5, 1.5);
			ProgressCircle.RenderScale = FVector2D(1.5, 1.5);
		}
		else
		{
			InnerCircle.RenderScale = FVector2D(1.75, 1.75);
			ProgressCircle.RenderScale = FVector2D(1.75, 1.75);
		}

		// Show the correct mash/hold indicator
		if (MashSettings.IsButtonHold(Player))
		{
			ButtonMashIndicator.Visibility = ESlateVisibility::Hidden;
			HoldIndicator.Visibility = ESlateVisibility::HitTestInvisible;
		}
		else
		{
			HoldIndicator.Visibility = ESlateVisibility::Hidden;
			ButtonMashIndicator.Visibility = ESlateVisibility::HitTestInvisible;
		}
	}
};