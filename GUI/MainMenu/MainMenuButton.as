class UMainMenuButton : UMenuButtonWidget
{
	UPROPERTY(BindWidget)
	UWidget RegularBackground;
	UPROPERTY(BindWidget)
	UWidget HoverBackground;
	UPROPERTY(BindWidget)
	UWidget LineBox;

	UPROPERTY(Transient, Meta = (BindWidgetAnim))
	UWidgetAnimation Enter;

	UPROPERTY(BindWidget)
	UImage LineUp;
	UPROPERTY(BindWidget)
	UImage LineDown;
	UPROPERTY(BindWidget)
	UImage DotSelected;

	UPROPERTY(BindWidget)
	UTextBlock ButtonText;

	UPROPERTY(BindWidget)
	UWidget DemoCallout;

	UPROPERTY(EditAnywhere, Category = "Main Menu Button")
	FText Text;

	UPROPERTY(EditAnywhere, Category = "Main Menu Button")
	bool bIsFirstOption = false;
	UPROPERTY(EditAnywhere, Category = "Main Menu Button")
	bool bIsLastOption = false;

	uint LastVisibleFrame = 0;

	UPROPERTY(EditAnywhere)
	float AnimationTime = 0;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool bIsDesignTime)
	{
		if (!Text.IsEmpty())
			ButtonText.Text = Text;
	}

	void AnimateVisible(float Delay)
	{
		if (Delay == 0.0)
		{
			MakeVisible();
		}
		else
		{
			PlayAnimation(Enter, PlaybackSpeed = 0.0);
			Timer::SetTimer(this, n"MakeVisible", Delay);
		}
	}

	UFUNCTION()
	private void MakeVisible()
	{
		PlayAnimation(Enter);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		if (Game::IsNarrationEnabled())
			Game::NarrateText(Text);

		return Super::OnFocusReceived(MyGeometry, InFocusEvent);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		float WantedTextOffset = 0.0;
		if (IsHoveredOrActive())
		{
			HoverBackground.Visibility = ESlateVisibility::Visible;
			RegularBackground.Visibility = ESlateVisibility::Hidden;
			DotSelected.Visibility = ESlateVisibility::HitTestInvisible;
			ButtonText.SetColorAndOpacity(FLinearColor(0.0, 0.0, 0.0));
			WantedTextOffset = 30.0;
		}
		else
		{
			HoverBackground.Visibility = ESlateVisibility::Hidden;
			DotSelected.Visibility = ESlateVisibility::Hidden;
			RegularBackground.Visibility = ESlateVisibility::Visible;
			ButtonText.SetColorAndOpacity(FLinearColor::White);
			WantedTextOffset = 0.0;
			AnimationTime = 0;
		}
		AnimationTime += InDeltaTime;
		
		auto LineSlot = Cast<UHorizontalBoxSlot>(LineBox.Slot);
		FMargin TextPadding = LineSlot.Padding;
		if (LastVisibleFrame < GFrameNumber-1)
			TextPadding.Right = WantedTextOffset;
		else
			TextPadding.Right = Math::FInterpTo(TextPadding.Right, WantedTextOffset, InDeltaTime, 7.0);

		LastVisibleFrame = GFrameNumber;
		LineSlot.SetPadding(TextPadding);

		if (bIsFirstOption)
			LineUp.Visibility = ESlateVisibility::Hidden;
		else
			LineUp.Visibility = ESlateVisibility::HitTestInvisible;

		if (bIsLastOption)
			LineDown.Visibility = ESlateVisibility::Hidden;
		else
			LineDown.Visibility = ESlateVisibility::HitTestInvisible;
	}
};