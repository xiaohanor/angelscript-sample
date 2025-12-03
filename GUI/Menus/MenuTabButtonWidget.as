
event void FOnMenuTabButtonClicked(UMenuTabButtonWidget Widget);

class UMenuTabButtonWidget : UHazeUserWidget
{
	default bIsFocusable = false;
	default Visibility = ESlateVisibility::Visible;

	UPROPERTY()
	FOnMenuTabButtonClicked OnClicked;

	UPROPERTY()
	FOnMenuTabButtonClicked OnFocused;

	UPROPERTY(BlueprintReadOnly)
	bool bIsActiveTab = false;

	UPROPERTY(BlueprintReadOnly)
	bool bHovered = false;

	UPROPERTY(BlueprintReadOnly)
	bool bPressed = false;

	UFUNCTION(BlueprintOverride)
	void OnMouseEnter(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.CursorDelta.IsNearlyZero())
			return;
		bHovered = true;
		OnFocused.Broadcast(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseLeave(FPointerEvent MouseEvent)
	{
		bHovered = false;
		bPressed = false;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.EffectingButton == EKeys::LeftMouseButton && !MouseEvent.IsRepeat())
		{
			bPressed = true;
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonUp(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.EffectingButton == EKeys::LeftMouseButton && !MouseEvent.IsRepeat())
		{
			if (bPressed)
			{
				bPressed = false;
				OnClicked.Broadcast(this);
			}
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}
};