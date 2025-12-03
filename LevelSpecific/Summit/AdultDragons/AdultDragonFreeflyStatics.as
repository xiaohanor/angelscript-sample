namespace AdultDragonFreeFlying
{
	UFUNCTION()
	AAdultDragonFreeFlyingRubberBandSpline FindClosestFreeFlySplineToLocation(FVector Location)
	{
		TListedActors<AAdultDragonFreeFlyingRubberBandSpline> FreeflySplines;
		AAdultDragonFreeFlyingRubberBandSpline ClosestFreeflySpline = FreeflySplines.Array[0];
		float ClosestDistance = ClosestFreeflySpline.Spline.GetClosestSplineWorldLocationToWorldLocation(Location).DistSquared(Location);
		for (auto FreeflySpline : FreeflySplines)
		{
			if (FreeflySpline.Spline.GetClosestSplineWorldLocationToWorldLocation(Location).DistSquared(Location) < ClosestDistance)
				ClosestFreeflySpline = FreeflySpline;
		}
		return ClosestFreeflySpline;
	}
}