class UIslandRedBlueTargetableWidget : UTargetableWidget
{
	UPROPERTY(Meta = (BindWidget))
	UImage Image;

	// Increase this number to increase the targetable widget size
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Targetable")
	float WidgetScale = 2000.0;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		Image.SetVisibility(bIsPrimaryTarget ? ESlateVisibility::Visible : ESlateVisibility::Hidden);

		FVector CameraLocation = Player.GetViewLocation();
		float Distance = CameraLocation.Distance(WidgetWorldPosition);

		float Scale = WidgetScale / Distance;
		Image.SetRenderScale(FVector2D(Scale, Scale));
	}
}