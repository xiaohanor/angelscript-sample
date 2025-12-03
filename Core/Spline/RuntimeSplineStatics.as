
UFUNCTION(BlueprintCallable, Category = "Runtime Spline")
mixin void BP_DrawDebugSpline(FHazeRuntimeSpline InSpline, int NumSegments = 150, float Width = 10, float Duration = 0.0, bool bDrawInForeground = false)
{
	InSpline.DrawDebugSpline(NumSegments, Width, Duration, bDrawInForeground);
}

mixin void DrawDebugSplineRelativeTo(FHazeRuntimeSpline InSpline, FTransform RelativeTo, int NumSegments = 150, float Width = 10, float Duration = 0.0, bool bDrawInForeground = false)
{
	FHazeRuntimeSpline Spline;
	for(int i = 0; i < InSpline.Points.Num(); i++)
	{
		Spline.AddPoint(RelativeTo.TransformPosition(InSpline.Points[i]));
	}
	Spline.DrawDebugSpline(NumSegments, Width, Duration, bDrawInForeground);
}

mixin void DrawDebugSpline(FHazeRuntimeSpline InSpline, int NumSegments = 150, float Width = 10, float Duration = 0.0, bool bDrawInForeground = false)
{
	if(InSpline.Points.Num() < 2)
		return;

	// start spline point
	Debug::DrawDebugPoint(InSpline.Points[0], Width * 3, FLinearColor::Green, Duration, bDrawInForeground);

	// end spline point
	Debug::DrawDebugPoint(InSpline.Points.Last(), Width * 3, FLinearColor::Blue, Duration, bDrawInForeground);

	// draw all splint points that we've assigned
	for(int i = 1; i < InSpline.Points.Num() - 1; i++)
		Debug::DrawDebugPoint(InSpline.Points[i], Width, FLinearColor::Purple, Duration, bDrawInForeground);

	// Find 150 uniformerly distributed locations on the spline
	TArray<FVector> Locations;
	InSpline.GetLocations(Locations, NumSegments);

	// Draw all locations that we've found on the spline
	for(FVector L : Locations)
		Debug::DrawDebugPoint(L, Width, FLinearColor::Black, Duration, bDrawInForeground);

	// Draw a location moving along the spline based on elasped time
	Debug::DrawDebugPoint(InSpline.GetLocation((Time::GetGameTimeSeconds() * 0.2) % 1.0), Width * 3, FLinearColor::White, Duration, bDrawInForeground);
}

enum EDebugDrawRuntimeSplineLineType
{
	None,
	Points,
	Lines,
};

struct FDebugDrawRuntimeSplineParams
{
	EDebugDrawRuntimeSplineLineType LineType = EDebugDrawRuntimeSplineLineType::Points;
	int NumSegments = 150;
	FLinearColor LineColor = FLinearColor::Black;
	float Width = 10;
	float Duration = 0.0;
	bool bDrawInForeground = false;

	bool bDrawStartPoint = true;
	FLinearColor StartPointColor = FLinearColor::Green;

	bool bDrawEndPoint = true;
	FLinearColor EndPointColor = FLinearColor::Green;

	bool bDrawSplinePoints = true;
	FLinearColor SplinePointColor = FLinearColor::Purple;

	bool bDrawMovingPoint = true;
	FLinearColor MovingPointColor = FLinearColor::White;
	float MovingPointSpeed = 0.2;
};

mixin void DrawDebugSplineWithLines(FHazeRuntimeSpline InSpline, int NumSamples = 150)
{
	if(InSpline.Points.Num() < 2)
		return;

	TArray<FVector> Locations;
	Locations.Reserve(NumSamples);
	InSpline.GetLocations(Locations, NumSamples);
	for(int i = 1; i < Locations.Num(); ++i)
	{
		FVector A = Locations[i];
		FVector B = Locations[i-1];
		Debug::DrawDebugLine(A, B, FLinearColor::Yellow, 5.0, 0.0);
	}
}

mixin void DrawDebugSpline(FHazeRuntimeSpline InSpline, FDebugDrawRuntimeSplineParams Params)
{
	if(InSpline.Points.Num() < 2)
		return;

	if(Params.bDrawStartPoint)
	{
		// start spline point
		Debug::DrawDebugPoint(InSpline.Points[0], Params.Width * 3, Params.StartPointColor, Params.Duration, Params.bDrawInForeground);
	}

	if(Params.bDrawSplinePoints)
	{
		// draw all splint points that we've assigned
		for(int i = 1; i < InSpline.Points.Num() - 1; i++)
			Debug::DrawDebugPoint(InSpline.Points[i], Params.Width, Params.SplinePointColor, Params.Duration, Params.bDrawInForeground);
	}

	if(Params.bDrawEndPoint)
	{
		// end spline point
		Debug::DrawDebugPoint(InSpline.Points.Last(), Params.Width * 3, Params.EndPointColor, Params.Duration, Params.bDrawInForeground);
	}

	switch(Params.LineType)
	{
		case EDebugDrawRuntimeSplineLineType::None:
			break;

		case EDebugDrawRuntimeSplineLineType::Points:
		{
			// Find 150 uniformerly distributed locations on the spline
			TArray<FVector> Locations;
			InSpline.GetLocations(Locations, Params.NumSegments);

			// Draw all locations that we've found on the spline
			for(FVector L : Locations)
				Debug::DrawDebugPoint(L, Params.Width, Params.LineColor, Params.Duration, Params.bDrawInForeground);

			break;
		}

		case EDebugDrawRuntimeSplineLineType::Lines:
		{
			// Find 150 uniformerly distributed locations on the spline
			TArray<FVector> Locations;
			InSpline.GetLocations(Locations, Params.NumSegments);

			for(int i = 1; i < Locations.Num(); i++)
			{
				Debug::DrawDebugLine(Locations[i - 1], Locations[i], Params.LineColor, Params.Width, Params.Duration, Params.bDrawInForeground);
			}

			break;
		}
	}

	if(Params.bDrawMovingPoint)
	{
		// Draw a location moving along the spline based on elasped time
		Debug::DrawDebugPoint(InSpline.GetLocation((Time::GetGameTimeSeconds() * Params.MovingPointSpeed) % 1.0), Params.Width * 3, Params.MovingPointColor, Params.Duration, Params.bDrawInForeground);
	}
}

mixin void VisualizeSpline(FHazeRuntimeSpline InSpline, UHazeScriptComponentVisualizer Visualizer, int NumSegments = 150, float Width = 10)
{
	if(InSpline.Points.Num() < 2)
		return;

	// start spline point
	Visualizer.DrawPoint(InSpline.Points[0], FLinearColor::Green, Width * 3);

	// end spline point
	Visualizer.DrawPoint(InSpline.Points.Last(), FLinearColor::Blue, Width * 3);

	// draw all splint points that we've assigned
	for(FVector P : InSpline.Points)
		Visualizer.DrawPoint(P, FLinearColor::Purple, Width * 1.5);

	// Find 150 uniformerly distributed locations on the spline
	TArray<FVector> Locations;
	InSpline.GetLocations(Locations, NumSegments);

	// Draw all locations that we've found on the spline
	for(FVector L : Locations)
		Visualizer.DrawPoint(L, FLinearColor::Black, Width);


	// Draw a location moving along the spline based on elasped time
	Visualizer.DrawPoint(InSpline.GetLocation((Time::GetGameTimeSeconds() * 0.2) % 1.0), FLinearColor::White, Width * 3);
}

mixin void VisualizeSplineSimple(FHazeRuntimeSpline InSpline, UHazeScriptComponentVisualizer Visualizer, int NumSegments = 150, float Width = 10, FLinearColor DebugColor = FLinearColor::Black)
{
	if(InSpline.Points.Num() < 2)
		return;

	// start spline point
	Visualizer.DrawPoint(InSpline.Points[0], FLinearColor::Green, Width * 3);

	if(!InSpline.Looping)
	{
		// end spline point
		Visualizer.DrawPoint(InSpline.Points.Last(), FLinearColor::Blue, Width * 3);
	}

	// Find 150 uniformerly distributed locations on the spline
	TArray<FVector> Locations;
	InSpline.GetLocations(Locations, NumSegments);

	for(int i = 0; i < Locations.Num() - 1; ++i)
	{
	
		FVector P0 = Locations[i];
		FVector P1 = Locations[i+1];
		Visualizer.DrawLine(P0, P1, DebugColor, Width);
	}

	// Draw a location moving along the spline based on elasped time
	Visualizer.DrawPoint(InSpline.GetLocation((Time::GetGameTimeSeconds() * 0.2) % 1.0), FLinearColor::White, Width * 3);
}

/** Build Runtime Spline by walking along the HazeSpline and sampling it.
 * 	By default it'll sample the spline 100 times, but that can be overriden by
 *  specifing the desired SampleStepSizeDistance.
 */
UFUNCTION(BlueprintCallable, Category = "Runtime Spline")
mixin FHazeRuntimeSpline BuildRuntimeSplineFromHazeSpline(const UHazeSplineComponent HazeSpline, float SampleStepSizeDistance = -1.0)
{
	if(HazeSpline == nullptr)
		return FHazeRuntimeSpline();

	return HazeSpline.ComputedSpline.BuildRuntimeSplineFromComputeSpline(HazeSpline.WorldTransform, SampleStepSizeDistance);
}

/** Build Runtime Spline by walking along the HazeSpline and sampling it.
 * 	By default it'll sample the spline 100 times, but that can be overriden by
 *  specifing the desired SampleStepSizeDistance.
 * 
 *  The result will be in local space unless a WorldTransform is given in order to Transform the RuntimeSpline into that space. 
 *  Normally the WorldTransform would be HazeSplineComponent.WorldTransform, but we don't have that here. 
 */
UFUNCTION(BlueprintCallable, Category = "Runtime Spline")
mixin FHazeRuntimeSpline BuildRuntimeSplineFromComputeSpline(FHazeComputedSpline ComputedSpline, FTransform WorldTransform, float SampleStepSizeDistance = -1.0)
{
	if(ComputedSpline.Points.Num() <= 0)
		return FHazeRuntimeSpline();

	const float SplineLength = ComputedSpline.SplineLength;
	if(SplineLength <= 0)
		return FHazeRuntimeSpline();

	float StepSizeDistance = SampleStepSizeDistance;
	if(SampleStepSizeDistance != -1)
		StepSizeDistance = Math::Max(KINDA_SMALL_NUMBER, SampleStepSizeDistance);
	else
		StepSizeDistance = SplineLength * 0.01;		// Default: 100 samples

	const int Loops = Math::Max(Math::RoundToInt(SplineLength / StepSizeDistance), 2);

	TArray<FVector> Locations;
	TArray<FVector> UpDirections;
	Locations.Reserve(Loops);
	UpDirections.Reserve(Loops);

	float CurrentSplineDistance = 0;
	float DistanceBetweenPoints = SplineLength / float(Loops);
	for(int i = 0; i <= Loops; ++i)
	{
		const FTransform LocalSplineSample = SplineComputation::GetRelativeTransformAtSplineDistance(ComputedSpline, CurrentSplineDistance);
		const FTransform WorldSplineSample = LocalSplineSample * WorldTransform;

		Locations.Add(WorldSplineSample.Location);
		UpDirections.Add(WorldSplineSample.Rotation.UpVector);

		CurrentSplineDistance += DistanceBetweenPoints;
	}

	FHazeRuntimeSpline RuntimeSpline = FHazeRuntimeSpline();
	RuntimeSpline.Points = Locations;
	RuntimeSpline.UpDirections = UpDirections;
	
	// RuntimeSpline.DrawDebugSpline();

	return RuntimeSpline;
}
