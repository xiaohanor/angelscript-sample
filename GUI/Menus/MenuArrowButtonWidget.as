
event void FOnMenuArrowButtonClicked(UMenuArrowButtonWidget Widget);

class UMenuArrowButtonWidget : UHazeUserWidget
{
	default bIsFocusable = false;
	default Visibility = ESlateVisibility::Visible;

	UPROPERTY(EditAnywhere)
	UTexture2D ButtonImage;

	UPROPERTY(EditAnywhere)
	UTexture2D HoveredImage;

	UPROPERTY(EditAnywhere)
	UTexture2D PressedImage;

	UPROPERTY(EditAnywhere)
	UTexture2D DisabledImage;

	UPROPERTY(EditAnywhere)
	FText ButtonText;

	UPROPERTY(EditAnywhere, AdvancedDisplay)
	bool bRepeats = true;
	
	UPROPERTY(EditAnywhere, AdvancedDisplay)
	bool bScaleDownWhenPressed = false;

	UPROPERTY(BindWidget)
	UOverlay MainOverlay;

	UPROPERTY(BindWidget)
	UImage MainImage;

	UPROPERTY(EditAnywhere)
	float ImagePadding = 0;

	UPROPERTY(BindWidget)
	UTextBlock MainText;

	UPROPERTY()
	FOnMenuArrowButtonClicked OnClicked;

	UPROPERTY()
	FOnMenuArrowButtonClicked OnFocused;

	UPROPERTY(BlueprintReadOnly)
	bool bHovered = false;

	UPROPERTY(BlueprintReadOnly)
	bool bPressed = false;

	UPROPERTY(BlueprintReadOnly)
	bool bDisabled = false;

	UPROPERTY(BlueprintReadOnly)
	bool bClickable = true;

	float MouseRepeatTime = -1.0;
	int MouseRepeatCount = 0;
	bool bPulsing = false;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool bIsDesignTime)
	{
		if (!ButtonText.IsEmpty())
		{
			MainText.Text = ButtonText;
			MainText.Visibility = ESlateVisibility::HitTestInvisible;
		}
		else
		{
			MainText.Visibility = ESlateVisibility::Collapsed;
		}

		if (ButtonImage != nullptr)
		{
			MainImage.SetBrushFromTexture(ButtonImage);
			MainImage.Visibility = ESlateVisibility::Visible;
		}
		else
		{
			MainImage.Visibility = ESlateVisibility::Hidden;
		}

		auto ImageSlot = Cast<UOverlaySlot>(MainImage.Slot);
		ImageSlot.SetPadding(FMargin(ImagePadding));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		UTexture2D CurrentImage;
		if (bDisabled)
			CurrentImage = DisabledImage;
		else if (bPressed && PressedImage != nullptr)
			CurrentImage = PressedImage;
		else if (bHovered && HoveredImage != nullptr)
			CurrentImage = HoveredImage;
		else
			CurrentImage = ButtonImage;

		if (CurrentImage != nullptr)
		{
			MainImage.SetBrushFromTexture(CurrentImage);
			MainImage.Visibility = ESlateVisibility::Visible;
		}
		else
		{
			MainImage.Visibility = ESlateVisibility::Hidden;
		}

		if (bScaleDownWhenPressed)
		{
			if (bPressed)
				MainOverlay.SetRenderScale(FVector2D(0.85, 0.85));
			else
				MainOverlay.SetRenderScale(FVector2D(1.0, 1.0));
		}

		if (MainText.IsVisible())
		{
			FSlateColor Color;
			if (bPressed)
				Color.SpecifiedColor = FLinearColor(0.2, 1.0, 0.8);
			else if (bHovered)
				Color.SpecifiedColor = FLinearColor(0.0, 1.0, 0.5);
			else
				Color.SpecifiedColor = FLinearColor(1.0, 1.0, 1.0);

			MainText.SetColorAndOpacity(Color);
		}

		if (bPressed && MouseRepeatTime > 0.0 && !bDisabled)
		{
			if (Time::PlatformTimeSeconds > MouseRepeatTime)
			{
				OnClicked.Broadcast(this);
				MouseRepeatCount += 1;

				MouseRepeatTime = Time::PlatformTimeSeconds + Math::Lerp(
					0.1, 0.01,
					Math::Clamp(float(MouseRepeatCount - 10) / 20.0, 0.0, 1.0)
					);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseEnter(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.CursorDelta.IsNearlyZero())
			return;
		if (!bClickable || bDisabled)
			return;
		bHovered = true;
		OnFocused.Broadcast(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseLeave(FPointerEvent MouseEvent)
	{
		bHovered = false;
		bPressed = false;
		MouseRepeatTime = -1.0;
		MouseRepeatCount = 0;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.EffectingButton == EKeys::LeftMouseButton && bClickable && !bDisabled)
		{
			bPressed = true;
			MouseRepeatTime = Time::PlatformTimeSeconds + 0.4;
			MouseRepeatCount = 0;
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDoubleClick(FGeometry InMyGeometry, FPointerEvent InMouseEvent)
	{
		if (InMouseEvent.EffectingButton == EKeys::LeftMouseButton && bClickable && !bDisabled)
		{
			bPressed = true;
			MouseRepeatTime = Time::PlatformTimeSeconds + 0.4;
			MouseRepeatCount = 0;
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonUp(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.EffectingButton == EKeys::LeftMouseButton && bClickable && !bDisabled)
		{
			if (bPressed)
			{
				bPressed = false;
				MouseRepeatTime = -1.0;
				MouseRepeatCount = 0;
				OnClicked.Broadcast(this);
			}
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}
};