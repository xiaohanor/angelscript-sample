/**
 * Yes, this struct is just a float
 * It used to have more stuff, but now it only has a float
 * Keeping it like this in case I need to add more data per point in the future...
 */
struct FPinballPredictedPathPoint
{
	/**
	 * How long time had passed since the start of the prediction when this point was added?
	 */
	float TimeOffset;
};

struct FPinballPredictedPath
{
	private bool bIsValid = false;
	private uint CreationFrame = 0;
	private float PredictDuration;
	private FHazeRuntimeSpline Spline;
	private TArray<FPinballPredictedPathPoint> Points;

	FVector InterpolatedLocation;
	FVector CorrectionVelocity;

	void Init(FVector InitialLocation, FVector InitialVelocity, float InPredictDuration)
	{
		Spline.SetCustomEnterTangentPoint(InitialVelocity);
		Spline.SetTension(0.5);

		AddPoint(InitialLocation, 0.0);

		CreationFrame = Time::FrameNumber;
		PredictDuration = InPredictDuration;
	}

	void AddPoint(FVector Location, float TimeOffset)
	{
		Spline.AddPoint(Location);

		FPinballPredictedPathPoint Point;
		Point.TimeOffset = TimeOffset;

		Points.Add(Point);
	}

	void FinishCreation(FVector ExitVelocity)
	{
		Spline.SetCustomExitTangentPoint(ExitVelocity);

		bIsValid = true;
	}

	bool IsValid() const
	{
		if(!bIsValid)
			return false;

		if(CreationFrame < Time::FrameNumber)
			return false;

		return true;
	}

	const FHazeRuntimeSpline GetSpline() const
	{
		return Spline;
	}

	void SetTension(float Tension)
	{
		Spline.SetTension(Tension);
	}

	FVector GetInitialLocation() const
	{
		return Spline.Points[0];
	}

	FVector GetPredictedLocation() const
	{
		return GetLocationAtTime(PredictDuration);
	}

	FVector GetExtrapolatedLocation() const
	{
		check(IsValid());
		return Spline.Points.Last();
	}

	float GetTotalTime() const
	{
		return Points.Last().TimeOffset;
	}

	FVector GetLocationAtTime(float Time) const
	{
		if (Time <= Points[0].TimeOffset)
			return Spline.Points[0];

		if (Time >= Points.Last().TimeOffset)
			return Spline.Points.Last();

		for (int i = 1; i < Points.Num(); ++i)
		{
			if (Time < Points[i].TimeOffset)
			{
				float PrevTime = Points[i - 1].TimeOffset;
				float Alpha = (Time - PrevTime) / (Points[i].TimeOffset - PrevTime);
				return Math::Lerp(Spline.Points[i-1], Spline.Points[i], Alpha);
			}
		}

		return Spline.Points.Last();
	}

	FVector GetForwardVectorAtTime(float Time) const
	{
		for (int i = 1; i < Points.Num(); ++i)
		{
			if (Time < Points[i].TimeOffset)
				return (Spline.Points[i] - Spline.Points[i-1]).GetSafeNormal();
		}

		return (Spline.Points.Last(0) - Spline.Points.Last(1)).GetSafeNormal();
	}

	float GetTimeClosestToLocation(FVector Location) const
	{
		float ClosestTime = 0.0;
		float ClosestDist = MAX_flt;

		for (int i = 1; i < Points.Num(); ++i)
		{
			FVector Start = Spline.Points[i-1];
			FVector End = Spline.Points[i];

			FVector Delta = End - Start;
			float DeltaSize = Delta.Size();

			if (DeltaSize <= SMALL_NUMBER)
			{
				float Dist = Start.DistSquared(Location);
				if (Dist < ClosestDist)
				{
					ClosestTime = Points[i - 1].TimeOffset;
					ClosestDist = Dist;
				}

				continue;
			}

			FVector Offset = Location - Start;
			FVector LineDirection = Delta / DeltaSize;

			float Dot = LineDirection.DotProduct(Offset) / DeltaSize;
			float Alpha = Math::Saturate(Dot);

			FVector Closest = Start + Delta * Alpha;
			float Dist = Closest.DistSquared(Location);
			if (Dist < ClosestDist)
			{
				ClosestTime = Points[i - 1].TimeOffset + Alpha * (Points[i].TimeOffset - Points[i - 1].TimeOffset);
				ClosestDist = Dist;
			}
		}

		return ClosestTime;
	}

	void Invalidate()
	{
		bIsValid = false;
	}
};