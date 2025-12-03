UCLASS(Abstract)
class UGravityBikeWhipGrabWidget : UHazeUserWidget
{
	UPROPERTY(Category = "Whip Grab Target Component")
	float WidgetAccelerateDuration = 0.5;

	UPROPERTY(Category = "Whip Grab Target Component")
	float WidgetInterpSpeed = 5;

	UFUNCTION(BlueprintEvent)
	void Show() {}

	FVector2D GetScreenSpacePositionUV() const
	{
		auto WidgetSlot = Cast<UCanvasPanelSlot>(Slot);
		return WidgetSlot.GetAnchors().Maximum;
	}

	void SetScreenSpacePositionUV(FVector2D ScreenUV)
	{
		auto WidgetSlot = Cast<UCanvasPanelSlot>(Slot);
		FAnchors CrosshairAnchors;
		CrosshairAnchors.Minimum = ScreenUV;
		CrosshairAnchors.Maximum = ScreenUV;

		WidgetSlot.Anchors = CrosshairAnchors;
		WidgetSlot.Offsets = FMargin();
		WidgetSlot.Alignment = FVector2D(0.5, 0.5);
		WidgetSlot.Position = FVector2D(0.0, 0.0);
	}
};