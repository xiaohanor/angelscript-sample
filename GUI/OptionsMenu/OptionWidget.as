
event void FOnOptionFocused(UOptionWidget Widget);

class UOptionWidget : UHazeUserWidget
{
	default bIsFocusable = true;
	default Visibility = ESlateVisibility::Visible;

	void Apply() {}
	void Reset() {}
	void Refresh() {}
	FText GetDescription() const { return FText(); }

	UPROPERTY()
	FOnOptionFocused OnOptionFocused;

	UPROPERTY(BlueprintReadOnly)
	bool bFocused = false;

	UPROPERTY(BlueprintReadOnly)
	bool bFocusedByMouse = false;

	UPROPERTY(BlueprintReadOnly)
	bool bFocusedByNavigation = false;

	UPROPERTY(BlueprintReadOnly)
	bool bHovered = false;

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
		bFocusedByNavigation = (InFocusEvent.Cause == EFocusCause::Navigation);
		OnOptionFocused.Broadcast(this);
		return FEventReply::Handled();
	}

	UFUNCTION(BlueprintOverride)
	void OnFocusLost(FFocusEvent InFocusEvent)
	{
		bFocused = false;
		bFocusedByMouse = false;
		bFocusedByNavigation = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseEnter(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.CursorDelta.IsNearlyZero())
			return;
		bHovered = true;

		// OnFocusReceived won't be triggered if already focused.
		if (HasAnyUserFocus())
			OnOptionFocused.Broadcast(this);

		Widget::SetAllPlayerUIFocus(this, EFocusCause::Mouse);
	}

	UFUNCTION(BlueprintOverride)
	void OnMouseLeave(FPointerEvent MouseEvent)
	{
		bHovered = false;
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseMove(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if (MouseEvent.CursorDelta.IsNearlyZero())
			return FEventReply::Unhandled();
		return FEventReply::Unhandled().SetUserFocus(this, EFocusCause::Mouse);
	}

	FString GetFullNarrationText() { /* Virutal */ return FString();}
	
}