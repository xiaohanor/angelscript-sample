class UScalableSlicedImage : UHazeUserWidget
{
	UPROPERTY(EditAnywhere)
	bool bFitHorizontally = true;
	UPROPERTY(EditAnywhere)
	FSlateBrush Brush;

	UFUNCTION(BlueprintOverride)
	void OnPaint(FPaintContext& Context) const
	{
		FGeometry Geometry = Context.GetAllottedGeometry();
		if (Geometry.LocalSize.Y <= 0)
			return;
		if (Brush.ImageSize.Y <= 0)
			return;

		float ScaleY = Geometry.LocalSize.Y / Math::Max(Brush.ImageSize.Y, 1);
		float ScaleX = Geometry.LocalSize.X / Math::Max(Brush.ImageSize.X, 1);

		float Scale;
		if (bFitHorizontally)
			Scale = ScaleY;
		else
			Scale = ScaleX;

		Scale = Math::Clamp(Scale, 0.01, 1.0);

		FVector2D LayoutSize = FVector2D(
			Geometry.LocalSize.X/Scale, Geometry.LocalSize.Y/Scale
		);

		FGeometry DrawGeometry = Geometry
		.MakeChild(
			(Geometry.LocalSize - LayoutSize) * 0.5,
			LayoutSize,
		)
		.MakeTransformedChild(
			FVector2D(0, 0),
			FVector2D(Scale, Scale),
		);
		
		FSlateBrush DrawBrush = Brush;
		Context.DrawBox(DrawGeometry, DrawBrush, ColorAndOpacity);
	}

	void SetBrushFromTexture(UTexture2D Texture)
	{
		Brush.ResourceObject = Texture;
	}

	void SetBrushColor(FLinearColor Color)
	{
		Brush.TintColor = Color;
	}
}