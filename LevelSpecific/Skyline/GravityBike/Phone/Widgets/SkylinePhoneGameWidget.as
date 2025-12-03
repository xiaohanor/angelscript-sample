UCLASS(Abstract)
class USkylinePhoneGameWidget : UHazeUserWidget
{
	ASkylineNewPhone Phone;

	FVector2D CursorPosition;
	bool bIsClickHeld = false;
	bool bGameActive = false;

	void SetCursorPosition(FVector2D NewPosition)
	{
		CursorPosition = NewPosition;
	}

	UFUNCTION()
	void OnClick(FVector2D CursorPos)
	{
		SetCursorPosition(CursorPos);
		bIsClickHeld = true;
	}

	UFUNCTION()
	void OnClickReleased()
	{
		bIsClickHeld = false;
	}

	void OnGameStarted()
	{
	}

	void GameComplete()
	{
		Phone.NextPhoneGame();
	}

	bool IsWidgetHovered(UWidget Widget) const
	{
		UCanvasPanelSlot CanvasSlot = Cast<UCanvasPanelSlot>(Widget.Slot);
		
		return IsWidgetHovered(CanvasSlot.Position, CanvasSlot.Size);
	}

	FVector2D GetWidgetLocation(UWidget Widget)
	{
		FVector2D Location = Widget.CachedGeometry.LocalToAbsolute(FVector2D(0,0));
		Location.X -= 400;
		Location.Y -= 800;
		Location.X += Widget.CachedGeometry.AbsoluteSize.X / 2;
		Location.Y += Widget.CachedGeometry.AbsoluteSize.Y / 2;
		return Location;
	}

	bool HoverScaleWidget(UWidget Widget, float InDeltaTime)
	{
		if(IsWidgetHovered(GetWidgetLocation(Widget), Widget.GetCachedGeometry().AbsoluteSize))
		{
			Widget.SetRenderScale(FVector2D::UnitVector * Math::FInterpConstantTo(Widget.GetRenderTransform().Scale.X, 1.2, InDeltaTime, 2));
		}
		else
		{
			Widget.SetRenderScale(FVector2D::UnitVector * Math::FInterpConstantTo(Widget.GetRenderTransform().Scale.X, 1, InDeltaTime, 2));
			return false;
		}

		return true;
	}

	bool IsWidgetHovered(FVector2D Position, FVector2D Size) const
	{
		if(CursorPosition.X < Position.X - Size.X / 2)
			return false;

		if(CursorPosition.X > Position.X + Size.X / 2)
			return false;

		if(CursorPosition.Y < Position.Y - Size.Y / 2)
			return false;

		if(CursorPosition.Y > Position.Y + Size.Y / 2)
			return false;

		return true;
	}
}