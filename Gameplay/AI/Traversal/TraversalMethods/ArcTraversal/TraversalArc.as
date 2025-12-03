struct FTraversalArc
{
	FVector LaunchLocation;
	FVector LaunchTangent;
	FVector LandLocation;
	FVector LandTangent;
	AActor LandArea;

	bool opEquals(FTraversalArc Other) const 
	{
		return (LaunchLocation == Other.LaunchLocation) &&
			   (LaunchTangent == Other.LaunchTangent) &&	
			   (LandTangent == Other.LandTangent) &&
			   (LandLocation == Other.LandLocation) && 
			   (LandArea == Other.LandArea);	
	}

	FVector GetLocation(float ArcFraction)
	{
		float Alpha = Math::Clamp(ArcFraction, 0.0, 1.0);
		return BezierCurve::GetLocation_2CP_ConstantSpeed(LaunchLocation, LaunchLocation + LaunchTangent, LandLocation - LandTangent, LandLocation, Alpha);
	}

	float GetLength()
	{
		return BezierCurve::GetLength_2CP(LaunchLocation, LaunchLocation + LaunchTangent, LandLocation - LandTangent, LandLocation);
	}

	void DrawDebug(FLinearColor Color, float Duration)
	{
		TArray<FVector> ArcLocs;
		GetLocations(40, ArcLocs);
		FVector DebugOffset = FVector(0.0, 0.0, 20.0);
		for (int i = 1; i < ArcLocs.Num(); i++)
		{
			Debug::DrawDebugLine(ArcLocs[i - 1] + DebugOffset, ArcLocs[i] + DebugOffset, Color, 3.0, Duration);
		}
	}

	void GetLocations(int NumPoints, TArray<FVector>& OutArcLocations)
	{
		int nPoints = Math::Max(NumPoints, 2);
		float Interval = 1.0 / (nPoints - 1.0);
		FVector LaunchControl = LaunchLocation + LaunchTangent;
		FVector LandControl = LandLocation - LandTangent;
		for (int i = 0; i < nPoints; i++)
		{
			OutArcLocations.Add(BezierCurve::GetLocation_2CP(LaunchLocation, LaunchControl, LandControl, LandLocation, i * Interval));
		}
	} 

	bool CanTraverse(FVector LaunchOffset, FVector LandOffset)
	{
		TArray<FVector> ArcLocs;
		GetLocations(10, ArcLocs);
		if (ArcLocs.Num() < 2)
			return false;

		float Interval = 1.0 / (ArcLocs.Num() - 1.0);
		FVector PrevLoc = ArcLocs[0] + LaunchOffset;
		for (int i = 1; i < ArcLocs.Num(); i++)
		{
			FVector Loc = ArcLocs[i] + Math::Lerp(LaunchOffset, LandOffset, i * Interval);
			if (!Traversal::IsTraversable(PrevLoc, Loc))
				return false;
			PrevLoc = Loc;
		}
		// All good!
		return true;
	}
}
