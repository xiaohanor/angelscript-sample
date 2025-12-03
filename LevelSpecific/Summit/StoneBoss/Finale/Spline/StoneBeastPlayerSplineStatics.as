namespace StonebeastPlayerSpline
{
	AStoneBeastPlayerSpline GetClosestPlayerSpline(FVector WorldLocation)
	{
		AStoneBeastPlayerSpline ClosestSpline;
		float ClosestDistanceSquared = BIG_NUMBER;
		for (auto PlayerSpline : TListedActors<AStoneBeastPlayerSpline>().Array)
		{
			const FVector ClosestSplineWorldLocation = PlayerSpline.Spline.GetClosestSplineWorldLocationToWorldLocation(WorldLocation);
			const float DistanceSquared = WorldLocation.DistSquared(ClosestSplineWorldLocation);
			if (DistanceSquared < ClosestDistanceSquared)
			{
				ClosestSpline = PlayerSpline;
				ClosestDistanceSquared = DistanceSquared;
			}
		}
		return ClosestSpline;
	}

	asset StoneBeastPlayerDefaultRespawnSettings of UStoneBeastPlayerRespawnSettings
	{
	}
}