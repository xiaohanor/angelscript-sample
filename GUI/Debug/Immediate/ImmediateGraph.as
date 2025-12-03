struct FImmediateGraphPoint
{
	FImmediateGraphPoint(float InKey, float InValue)
	{
		Key = InKey;
		Value = InValue;
	}

	float Key;
	float Value;

	FVector2D GetPlanePosition(FVector2D Size, float MinX, float MaxX, float MinY, float MaxY) const
	{
		// Flipped Min-Max for Y, since bigger Y is downwards
		FVector2D Alpha = FVector2D(Math::GetPercentageBetween(MinX, MaxX, Key), Math::GetPercentageBetween(MaxY, MinY, Value));
		return Size * Alpha;
	}
}

enum EImmediateGraphDrawMode
{
	Lines = 1,
	Points = 2,
	LinesAndPoints = 3,
}

struct FImmediateGraph
{
	// --- BOUNDS
	private bool bCustomMinX = false;
	private float MinX = 0.0;
	void SetCustomMinX(float InMinX) property
	{
		bCustomMinX = true;
		MinX = InMinX;
	}

	private bool bCustomMaxX = false;
	private float MaxX = 0.0;
	void SetCustomMaxX(float InMaxX) property
	{
		bCustomMaxX = true;
		MaxX = InMaxX;
	}

	private bool bCustomMinY = false;
	private float MinY = 0.0;
	void SetCustomMinY(float InMinY) property
	{
		bCustomMinY = true;
		MinY = InMinY;
	}

	private bool bCustomMaxY = false;
	private float MaxY = 0.0;
	void SetCustomMaxY(float InMaxY) property
	{
		bCustomMaxY = true;
		MaxY = InMaxY;
	}

	// --- Other settings
	EImmediateGraphDrawMode DrawMode = EImmediateGraphDrawMode::LinesAndPoints;
	bool bLabelAxes = true;
	float DefaultAxisPadding = 25.0;

	// --- Color settings
	FLinearColor PlaneBackgroundColor = FLinearColor(0.5, 0.0, 0.7, 0.2);
	FLinearColor PointColor = FLinearColor(0.7, 0.2, 1.0, 1.0);
	FLinearColor XAxisColor = FLinearColor(0.9, 0.1, 0.4, 1.0);
	FLinearColor YAxisColor = FLinearColor(0.1, 0.9, 0.4, 1.0);

	// Points
	TArray<FImmediateGraphPoint> Points;
	void AddPoint(float Key, float Value)
	{
		// Update bounds
		if ((Key < MinX || Points.Num() == 0) && !bCustomMinX)
			MinX = Key;
		if ((Key > MaxX || Points.Num() == 0) && !bCustomMaxX)
			MaxX = Key;

		if ((Value < MinY || Points.Num() == 0) && !bCustomMinY)
			MinY = Value;
		if ((Value > MaxY || Points.Num() == 0) && !bCustomMaxY)
			MaxY = Value;

		// Insert sorted
		bool bWasInserted = false;
		for(int i=0; i<Points.Num(); ++i)
		{
			if (Points[i].Key < Key)
			{
				Points.Insert(FImmediateGraphPoint(Key, Value), i);
				bWasInserted = true;
				break;
			}
		}

		if (!bWasInserted)
			Points.Add(FImmediateGraphPoint(Key, Value));
	}

	void AddPoints(TArray<FImmediateGraphPoint> InPoints)
	{
		for(auto Point : InPoints)
			AddPoint(Point.Key, Point.Value);
	}

	void Draw(FHazeImmediateSectionHandle Section, FVector2D Size = FVector2D(300.0, 100.0))
	{
		auto Canvas = Section.PaintCanvas();
		Canvas.Size(Size);
		Draw(Canvas, FVector2D::ZeroVector, Size);
	}
	void Draw(FHazeImmediatePaintCanvasHandle Canvas, FVector2D TopLeft, FVector2D Size)
	{
		float AxisPadding = DefaultAxisPadding;
		float PlanePadding = 10.0;

		if (!bLabelAxes)
			AxisPadding = 0.0;

		FVector2D BottomLeft = TopLeft + FVector2D(0.0, Size.Y);
		FVector2D BottomRight = TopLeft + Size;
		FVector2D TopRight = TopLeft + FVector2D(Size.X, 0.0);

		// -- Axis lines
		// X Axis
		Canvas.Line(BottomLeft + FVector2D(0.0, -AxisPadding), BottomRight + FVector2D(0.0, -AxisPadding), XAxisColor, 2.0);
		if (bLabelAxes)
		{
			Canvas.Line(BottomLeft + FVector2D(AxisPadding + PlanePadding, -AxisPadding + 3.0), BottomLeft + FVector2D(AxisPadding + PlanePadding, -AxisPadding), XAxisColor, 2.0);
			Canvas.Line(BottomRight + FVector2D(-PlanePadding, -AxisPadding + 3.0), BottomRight + FVector2D(-PlanePadding, -AxisPadding), XAxisColor, 2.0);

			Canvas.Text(BottomRight + FVector2D(0.0, -AxisPadding + 3.0), f"{MaxX:.2}", FLinearColor::White, FVector2D(1.1, -0.2), 0.8);
			Canvas.Text(BottomLeft + FVector2D(AxisPadding, -AxisPadding + 3.0), f"{MinX:.2}", FLinearColor::White, FVector2D(-0.1, -0.2), 0.8);
		}

		// Y Axis
		Canvas.Line(TopLeft + FVector2D(AxisPadding, 0.0), BottomLeft + FVector2D(AxisPadding, 0.0), YAxisColor, 2.0);
		if (bLabelAxes)
		{
			Canvas.Line(TopLeft + FVector2D(AxisPadding - 3.0, PlanePadding), TopLeft + FVector2D(AxisPadding, PlanePadding), YAxisColor, 2.0);
			Canvas.Line(BottomLeft + FVector2D(AxisPadding - 3.0, -AxisPadding - PlanePadding), BottomLeft + FVector2D(AxisPadding, -AxisPadding - PlanePadding), YAxisColor, 2.0);

			Canvas.Text(TopLeft + FVector2D(AxisPadding - 3.0, PlanePadding), f"{MaxY:.1}", FLinearColor::White, FVector2D(1.2, 0.5), 0.8);
			Canvas.Text(BottomLeft + FVector2D(AxisPadding - 3.0, -AxisPadding - PlanePadding), f"{MinY:.1}", FLinearColor::White, FVector2D(1.2, 0.5), 0.8);
		}

		// Graph plane
		FVector2D PlaneOrigin = FVector2D(AxisPadding + PlanePadding, PlanePadding);
		FVector2D PlaneSize = Size - FVector2D(AxisPadding + PlanePadding * 2, AxisPadding + PlanePadding * 2);
		Canvas.RectFill(BottomLeft + FVector2D(AxisPadding, -AxisPadding), TopRight, PlaneBackgroundColor);

		// Graph points
		for(int Index = 0; Index < Points.Num(); ++Index)
		{
			if (Points[Index].Key < MinX)
				continue;

			if (Points[Index].Key > MaxX)
				break;

			FVector2D PointPos = PlaneOrigin + Points[Index].GetPlanePosition(PlaneSize, MinX, MaxX, MinY, MaxY);

			if ((DrawMode & EImmediateGraphDrawMode::Points) > 0)
				Canvas.RectFill(PointPos - FVector2D(2.0, 2.0), PointPos + FVector2D(2.0, 2.0), PointColor);

			if ((DrawMode & EImmediateGraphDrawMode::Lines) > 0)
			{
				if (Index < Points.Num() - 1)
				{
					FVector2D NextPos = PlaneOrigin + Points[Index + 1].GetPlanePosition(PlaneSize, MinX, MaxX, MinY, MaxY);
					Canvas.Line(PointPos, NextPos, PointColor);
				}
			}
		}
	}
}