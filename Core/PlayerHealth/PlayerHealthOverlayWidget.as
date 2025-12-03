
class UPlayerHealthOverlayWidget : UHazeUserWidget
{
	UPROPERTY(Meta = (BindWidget))
	UHealthWheelWidget HealthWheel;

	void UpdateWheelPosition()
	{
		auto WheelSlot = Cast<UCanvasPanelSlot>(HealthWheel.Slot);

		FAnchors Anchors;
		FVector2D Position;
		FVector2D Alignment;

		if (Player.IsMio())
		{
			HealthWheel.SetRightSide(false);

			Anchors.Minimum = FVector2D(0.0, 1.0);
			Anchors.Maximum = FVector2D(0.0, 1.0);

			Position = FVector2D(0.0, 0.0);
			Alignment = FVector2D(0.0, 1.0);
		}
		else
		{
			HealthWheel.SetRightSide(true);

			Anchors.Minimum = FVector2D(1.0, 1.0);
			Anchors.Maximum = FVector2D(1.0, 1.0);

			Position = FVector2D(0.0, 0.0);
			Alignment = FVector2D(1.0, 1.0);
		}

		WheelSlot.SetAnchors(Anchors);
		WheelSlot.SetPosition(Position);
		WheelSlot.SetAlignment(Alignment);
		WheelSlot.SetSize(FVector2D(200.0, 200.0));
	}
};