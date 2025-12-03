namespace AdultDragonSpline
{
	FSplinePosition GetClosestSplinePosition(FVector Location)
	{
		TArray<AAdultDragonRespawnSpline> Splines = TListedActors<AAdultDragonRespawnSpline>().Array;
		FSplinePosition ClosestSplinePosition;
		float ClosestDistance = BIG_NUMBER;

		for (auto Spline : Splines)
		{
			FSplinePosition ClosestPoint = Spline.Spline.GetClosestSplinePositionToWorldLocation(Location);
			float Distance = ClosestPoint.WorldLocation.DistSquared(Location);
			if (Distance < ClosestDistance)
			{
				ClosestSplinePosition = ClosestPoint;
				ClosestDistance = Distance;
			}
		}

		return ClosestSplinePosition;
	}

	AAdultDragonRespawnSpline GetClosestSpline(FVector Location, FSplinePosition& OutClosestPosition)
	{
		OutClosestPosition = GetClosestSplinePosition(Location);
		if (OutClosestPosition.CurrentSpline == nullptr)
			return nullptr;

		return Cast<AAdultDragonRespawnSpline>(OutClosestPosition.CurrentSpline.Owner);
	}
}