namespace Jetski
{
	AJetskiRespawnSpline GetClosestRespawnSpline(FVector Location)
	{
		const TArray<AJetskiRespawnSpline> RespawnSplines = TListedActors<AJetskiRespawnSpline>().Array;

		if(RespawnSplines.IsEmpty())
			return nullptr;

		int ClosestIndex = 0;
		float ClosestDistanceSquared = BIG_NUMBER;
		for(int i = 0; i < RespawnSplines.Num(); i++)
		{
			const FVector ClosestLocation = RespawnSplines[i].Spline.GetClosestSplineWorldLocationToWorldLocation(Location);
			const float DistanceSquared = Location.DistSquared(ClosestLocation);
			if(DistanceSquared < ClosestDistanceSquared)
			{
				ClosestIndex = i;
				ClosestDistanceSquared = DistanceSquared;
			}
		}

		return RespawnSplines[ClosestIndex];
	}
}