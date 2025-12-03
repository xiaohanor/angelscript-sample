UCLASS(Abstract)
class UInitialBootSequencePage : UHazeUserWidget
{
	default bIsFocusable = true;
	default Visibility = ESlateVisibility::Visible;

	UPROPERTY(BindWidget)
	UInitialBootScaffold Scaffold;

	USplashScreenWidget SplashScreen;
	UHazePlayerIdentity Identity;

	protected bool bNarrateNextTick = false;

	void Show()
	{
		Scaffold.Show();
		bNarrateNextTick = true;
	}

	bool CanBackToPage() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (Identity != nullptr && Identity.TakesInputFromController(InKeyEvent.InputDeviceId))
		{
			if ((InKeyEvent.Key == EKeys::Gamepad_FaceButton_Top || InKeyEvent.Key == EKeys::F1) && SplashScreen.ShouldShowAccountPicker())
			{
				Online::PromptIdentitySignIn(Identity, true, FHazeOnOnlineIdentitySignedIn(SplashScreen, n"OnPendingIdentityChanged"));
				return FEventReply::Handled();
			}
		}
		return FEventReply::Unhandled();
	}
};


UCLASS(Abstract)
class UInitialBootScaffold : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UHazeTextWidget HeadingText;

	UPROPERTY(BindWidget)
	UWidget TooltipPanel;
	UPROPERTY(BindWidget)
	UImage DescriptionBackground;
	UPROPERTY(BindWidget)
	UTextBlock DescriptionTextBlock;

	UPROPERTY(Transient, Meta = (BindWidgetAnim))
	UWidgetAnimation ShowAnim;

	UPROPERTY(EditAnywhere)
	bool bShowHeading = true;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool IsDesignTime)
	{
		if (bShowHeading)
			HeadingText.Visibility = ESlateVisibility::HitTestInvisible;
		else
			HeadingText.Visibility = ESlateVisibility::Collapsed;
	}

	void Show()
	{
		if (bShowHeading)
			HeadingText.Visibility = ESlateVisibility::HitTestInvisible;
		else
			HeadingText.Visibility = ESlateVisibility::Collapsed;

		PlayAnimation(ShowAnim);
	}

	UFUNCTION()
	void SetHeading(FText Text)
	{
		HeadingText.SetText(Text);
	}

	void SetTooltip(FText Text, FGeometry AroundGeometry)
	{
		TooltipPanel.Visibility = ESlateVisibility::Visible;
		DescriptionTextBlock.SetText(Text);

		if (AroundGeometry.LocalSize.IsZero())
		{
			TooltipPanel.Visibility = ESlateVisibility::Hidden;
			return;
		}

		FVector2D OptionPos = AroundGeometry.LocalToAbsolute(FVector2D(0, AroundGeometry.LocalSize.Y * 0.5));
		FGeometry CanvasGeometry = TooltipPanel.Parent.GetCachedGeometry();
		FVector2D CanvasOptionPos = CanvasGeometry.AbsoluteToLocal(OptionPos);
		FVector2D CanvasOptionSize = AroundGeometry.LocalSize;
		FVector2D TooltipSize = TooltipPanel.GetCachedGeometry().LocalSize;

		auto TooltipSlot = Cast<UCanvasPanelSlot>(TooltipPanel.Slot);
		FMargin Margin = TooltipSlot.Offsets;
		Margin.Top = CanvasOptionPos.Y - TooltipSize.Y*0.5;
		Margin.Left = CanvasOptionPos.X + CanvasOptionSize.X + 10;
		DescriptionBackground.SetRenderScale(FVector2D(1.0, 1.0));

		if (Margin.Left + 350 >= CanvasGeometry.LocalSize.X)
			Margin.Left = CanvasGeometry.LocalSize.X - 350 - 10;
		
		TooltipSlot.SetOffsets(Margin);
	}

	void ClearTooltip()
	{
		TooltipPanel.Visibility = ESlateVisibility::Hidden;
	}

	void UpdateTooltipPosition()
	{

	}
}