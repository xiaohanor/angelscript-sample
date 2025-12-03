namespace FloatCurve
{
	
}

struct FRuntimeFloatCurveDrawParams
{
	FLinearColor CurveColor = FLinearColor::Red;

	bool bDrawFrame = true;
	FLinearColor FrameColor = FLinearColor::White;

	float FrameThickness = 0.0;
	float CurveThickness = 0.0;

	float SamplingSteps = 0.05;

	bool bUseCurveRanges = true;
	bool bLabelRanges = true;
	bool bDrawLinesToBottomEverySampleStep = false;

	float LabelScale = 1.0;
	float LabelOffset = 200.0;

	FVector2D TimeRange = FVector2D(0.0, 1.0);
	FVector2D ValueRange = FVector2D(0.0, 1.0);
}

mixin void DrawRuntimeFloatCurve(UHazeScriptComponentVisualizer Visualizer, FRuntimeFloatCurve Curve, FVector BottomLeftLocation, float Width, float Height, FVector UpVector = FVector::UpVector, FVector RightVector = FVector::RightVector, const FRuntimeFloatCurveDrawParams& DrawParams = FRuntimeFloatCurveDrawParams())
{
	// Draw frame
	const FVector BottomLeft = BottomLeftLocation;
	const FVector BottomRight = BottomLeftLocation + RightVector * Width;
	const FVector TopLeft = BottomLeftLocation + UpVector * Height;
	const FVector TopRight = TopLeft + RightVector * Width;

	if(DrawParams.bDrawFrame)
	{
		Visualizer.DrawLine(BottomLeft, BottomRight, DrawParams.FrameColor, DrawParams.FrameThickness);
		Visualizer.DrawLine(TopLeft, TopRight, DrawParams.FrameColor, DrawParams.FrameThickness);
		Visualizer.DrawLine(BottomLeft, TopLeft, DrawParams.FrameColor, DrawParams.FrameThickness);
		Visualizer.DrawLine(BottomRight, TopRight, DrawParams.FrameColor, DrawParams.FrameThickness);
	}

	if(Curve.NumKeys <= 0)
		return;

	float MinTime = DrawParams.TimeRange.X;
	float MaxTime = DrawParams.TimeRange.Y;
	float MinValue = DrawParams.ValueRange.X;
	float MaxValue = DrawParams.ValueRange.Y;

	if(DrawParams.bUseCurveRanges)
	{
		Curve.GetTimeRange(MinTime, MaxTime);
		Curve.GetValueRange(MinValue, MaxValue);
	}

	if(DrawParams.bLabelRanges)
	{
		Visualizer.DrawWorldString(f"X: {MinTime}", BottomLeft - UpVector * DrawParams.LabelOffset, DrawParams.FrameColor, DrawParams.LabelScale);
		Visualizer.DrawWorldString(f"X: {MaxTime}", BottomRight - UpVector * DrawParams.LabelOffset, DrawParams.FrameColor, DrawParams.LabelScale);

		Visualizer.DrawWorldString(f"Y: {MinValue}", BottomLeft - RightVector * DrawParams.LabelOffset, DrawParams.FrameColor, DrawParams.LabelScale);
		Visualizer.DrawWorldString(f"Y: {MaxValue}", TopLeft - RightVector * DrawParams.LabelOffset, DrawParams.FrameColor, DrawParams.LabelScale);
	}

	if(DrawParams.SamplingSteps <= 0.0)
	{
		devError("Sampling steps cannot be 0 or negative when drawing runtime float curves!");
		return;
	}

	float CurrentTime = 0.0;
	while(CurrentTime < 1.0)
	{
		const float NextTime = CurrentTime + DrawParams.SamplingSteps;
		
		// Gets the values but converted down to 0->1 range so it is easier to work with
		const float CurrentValue = Math::NormalizeToRange(Curve.GetFloatValue(Math::Lerp(MinTime, MaxTime, CurrentTime)), MinValue, MaxValue);
		float NextValue = Math::NormalizeToRange(Curve.GetFloatValue(Math::Lerp(MinTime, MaxTime, NextTime)), MinValue, MaxValue);
		if(NextValue >= 1.0)
			NextValue = 1.0;

		const FVector CurrentLocation = BottomLeft + RightVector * (CurrentTime * Width) + UpVector * (CurrentValue * Height);
		const FVector NextLocation = BottomLeft + RightVector * (NextTime * Width) + UpVector * (NextValue * Height);
		Visualizer.DrawLine(CurrentLocation, NextLocation, DrawParams.CurveColor, DrawParams.CurveThickness);

		if(DrawParams.bDrawLinesToBottomEverySampleStep && (!DrawParams.bDrawFrame || NextValue != 1.0))
		{
			Visualizer.DrawLine(NextLocation, NextLocation - UpVector * (NextValue * Height), DrawParams.CurveColor, DrawParams.CurveThickness);
		}

		CurrentTime = NextTime;
	}
}