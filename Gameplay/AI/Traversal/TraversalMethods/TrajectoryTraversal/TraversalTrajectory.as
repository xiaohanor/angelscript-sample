struct FTraversalTrajectory
{
	FVector LaunchLocation;
	FVector LaunchVelocity;
	FVector Gravity;
	FVector LandLocation;
	AActor LandArea;

	bool opEquals(FTraversalTrajectory Other) const 
	{
		return (LaunchLocation == Other.LaunchLocation) &&
			   (LaunchVelocity == Other.LaunchVelocity) &&
			   (Gravity == Other.Gravity) &&	
			   (LandLocation == Other.LandLocation) && 
			   (LandArea == Other.LandArea);	
	}

	FVector GetLocation(float Time) const
	{
		return LaunchLocation + LaunchVelocity * Time + Gravity * 0.5 * Math::Square(Time);
	}

	FVector GetVelocity(float Time) const
	{
		return LaunchVelocity + (Gravity * Time);
	}

	float GetTotalTime() const
	{
		// Assume constant horizontal speed
		FVector HorizontalDelta = (LandLocation - LaunchLocation).ConstrainToPlane(Gravity.GetSafeNormal());
		FVector HorizontalVelocity = LaunchVelocity.ConstrainToPlane(Gravity.GetSafeNormal());
		if (Gravity.SizeSquared2D() < KINDA_SMALL_NUMBER)
		{
			HorizontalDelta = (LandLocation - LaunchLocation);
			HorizontalDelta.Z = 0.0;
			HorizontalVelocity = LaunchVelocity;
			HorizontalVelocity.Z = 0.0;
		}
		else
		{
			// Uncomon case, gravity is not world up/down
			HorizontalDelta = (LandLocation - LaunchLocation).ConstrainToPlane(Gravity.GetSafeNormal());
			HorizontalVelocity = LaunchVelocity.ConstrainToPlane(Gravity.GetSafeNormal());
		}

		float HorizontalSpeedSqr = HorizontalVelocity.SizeSquared();
		if (HorizontalSpeedSqr < KINDA_SMALL_NUMBER)
			return BIG_NUMBER;
		return Math::Sqrt(HorizontalDelta.SizeSquared() / HorizontalSpeedSqr);
	}

	void DrawDebug(FLinearColor Color, float Duration, float Thickness = 3.0, int Resolution = 40) const
	{
		TArray<FVector> ArcLocs;
		GetLocations(Resolution, ArcLocs);
		FVector DebugOffset = FVector(0.0, 0.0, 20.0);
		for (int i = 1; i < ArcLocs.Num(); i++)
		{
			Debug::DrawDebugLine(ArcLocs[i - 1] + DebugOffset, ArcLocs[i] + DebugOffset, Color, Thickness, Duration);
		}
	}

	void GetLocations(int NumPoints, TArray<FVector>& OutLocations) const
	{
		float LandTime = GetTotalTime();
		if (LandTime == BIG_NUMBER)
			return;

		int nPoints = Math::Max(NumPoints, 2);
		float Interval = LandTime / (nPoints - 1.0);
		for (int i = 0; i < nPoints; i++)
		{
			float Time = (Interval * i);
			FVector Loc = LaunchLocation + LaunchVelocity * Time + Gravity * Math::Square(Time) * 0.5; 
			OutLocations.Add(Loc);
		}
	} 

	bool CanTraverse(FVector LaunchOffset, FVector LandOffset) const
	{
		TArray<FVector> Locs;
		GetLocations(10, Locs);
		if (Locs.Num() < 2)
			return false;

		float Interval = 1.0 / (Locs.Num() - 1.0);
		FVector PrevLoc = Locs[0] + LaunchOffset;
		for (int i = 1; i < Locs.Num(); i++)
		{
			FVector Loc = Locs[i] + Math::Lerp(LaunchOffset, LandOffset, i * Interval);
			if (!Traversal::IsTraversable(PrevLoc, Loc))
				return false;
			PrevLoc = Loc;
		}
		// All good!
		return true;
	}
}
