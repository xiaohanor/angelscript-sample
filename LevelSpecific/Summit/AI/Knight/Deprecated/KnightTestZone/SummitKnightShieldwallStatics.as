namespace SummitKnightShieldwall
{
	ASummitShieldwallInnerLayer FindClosestInnerShieldwall(FVector Location)
	{
		TListedActors<ASummitShieldwallInnerLayer> ShieldWalls;
		float ClosestDistSqr = BIG_NUMBER;
		ASummitShieldwallInnerLayer Closest = nullptr;
		for (ASummitShieldwallInnerLayer ShieldWall : ShieldWalls)
		{
			float DistSqr = Location.DistSquared(ShieldWall.ActorLocation);	
			if (DistSqr > ClosestDistSqr)
				continue;
			Closest = ShieldWall;
			ClosestDistSqr = DistSqr;
		}
		return Closest;
	}

	ASummitShieldWallMiddleLayer FindClosestMiddleShieldwall(FVector Location)
	{
		TListedActors<ASummitShieldWallMiddleLayer> ShieldWalls;
		float ClosestDistSqr = BIG_NUMBER;
		ASummitShieldWallMiddleLayer Closest = nullptr;
		for (ASummitShieldWallMiddleLayer ShieldWall : ShieldWalls)
		{
			float DistSqr = Location.DistSquared(ShieldWall.ActorLocation);	
			if (DistSqr > ClosestDistSqr)
				continue;
			Closest = ShieldWall;
			ClosestDistSqr = DistSqr;
		}
		return Closest;
	}
}
