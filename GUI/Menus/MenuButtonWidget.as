
event void FOnMenuButtonClicked(UMenuButtonWidget Button);

class UMenuButtonWidget : UHazeUserWidget
{
	default bIsFocusable = true;
	default Visibility = ESlateVisibility::Visible;

	UPROPERTY()
	FOnMenuButtonClicked OnClicked;
	UPROPERTY()
	FOnMenuButtonClicked OnFocused;

	UPROPERTY(BlueprintReadOnly)
	bool bFocused = false;

	UPROPERTY(BlueprintReadOnly)
	bool bFocusedByMouse = false;

	UPROPERTY(BlueprintReadOnly)
	bool bHovered = false;

	UPROPERTY(BlueprintReadOnly)
	bool bPressed = false;

	UPROPERTY(EditAnywhere)
	bool bClickable = true;

	float LastPressedTime;
	bool bPressedByGamepad = false;

	// Let's make this work. c:
	UPROPERTY(EditAnywhere, Category = "Audio")
	bool bTriggerEffectEvents = false; 

	UFUNCTION(BlueprintPure)
	bool IsHoveredOrActive()
	{
		if (bHovered && bFocused)
			return true;
		if (bFocused && !bFocusedByMouse)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnFocusReceived(FGeometry MyGeometry, FFocusEvent InFocusEvent)
	{
		bFocused = true;
		bFocusedByMouse = (InFocusEvent.Cause == EFocusCause::Mouse);
		OnFocused.Broadcast(this);

		if (bTriggerEffectEvents)
			UMenuEffectEventHandler::Trigger_OnDefaultHover(Menu::GetAudioActor(), FMenuActionData(this, true));

		return FEventReply::Handled();
	}

	UFUNCTION(BlueprintOverride)
	void OnFocusLost(FFocusEvent InFocusEvent)
	{
		bFocused = false;
		bPressed = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseEnter(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.CursorDelta.IsNearlyZero())
			return;
		if (!bClickable)
			return;

		bHovered = true;

		// OnFocusReceived won't be triggered if already focused.
		if (HasAnyUserFocus())
		{
			OnFocused.Broadcast(this);

			if (bTriggerEffectEvents)
				UMenuEffectEventHandler::Trigger_OnDefaultHover(Menu::GetAudioActor(), FMenuActionData(this, true));
		}
		
		Widget::SetAllPlayerUIFocus(this, EFocusCause::Mouse);
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseLeave(FPointerEvent MouseEvent)
	{
		if (!bClickable)
			return;
		bHovered = false;
		if (!bPressedByGamepad)
		{
			bPressed = false;
			bFocusedByMouse = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseMove(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (!bClickable)
			return FEventReply::Unhandled();
		if (MouseEvent.CursorDelta.IsNearlyZero())
			return FEventReply::Unhandled();
		return FEventReply::Unhandled().SetUserFocus(this, EFocusCause::Mouse);
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonDown(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (!bClickable)
			return FEventReply::Unhandled();

		if (MouseEvent.EffectingButton == EKeys::LeftMouseButton && !MouseEvent.IsRepeat())
		{
			bPressed = true;
			bPressedByGamepad = false;
			LastPressedTime = Time::RealTimeSeconds;
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonUp(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (!bClickable)
			return FEventReply::Unhandled();

		if (MouseEvent.EffectingButton == EKeys::LeftMouseButton && !MouseEvent.IsRepeat())
		{
			if (bPressed)
			{
				bPressed = false;
				OnClicked.Broadcast(this);

				if (bTriggerEffectEvents)
					UMenuEffectEventHandler::Trigger_OnDefaultClick(Menu::GetAudioActor(), FMenuActionData(this, true));
			}
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (!bClickable)
			return FEventReply::Unhandled();
		if (InKeyEvent.IsRepeat())
			return FEventReply::Unhandled();

		if (InKeyEvent.Key == EKeys::Enter || InKeyEvent.Key == EKeys::Virtual_Accept)
		{
			bPressed = true;
			bPressedByGamepad = true;
			LastPressedTime = Time::RealTimeSeconds;
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnKeyUp(FGeometry MyGeometry, FKeyEvent InKeyEvent)
	{
		if (!bClickable)
			return FEventReply::Unhandled();
		if (InKeyEvent.IsRepeat())
			return FEventReply::Unhandled();

		if (InKeyEvent.Key == EKeys::Enter || InKeyEvent.Key == EKeys::Virtual_Accept)
		{
			if (bPressed)
			{
				bPressed = false;
				OnClicked.Broadcast(this);

				if (bTriggerEffectEvents)
					UMenuEffectEventHandler::Trigger_OnDefaultClick(Menu::GetAudioActor(), FMenuActionData(this, false));
			}
			return FEventReply::Handled();
		}

		return FEventReply::Unhandled();
	}
};