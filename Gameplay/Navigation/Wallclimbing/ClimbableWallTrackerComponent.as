class UClimbableWallTrackerComponent : UActorComponent
{
	private TMap<UHazeActorSpawnPattern, FVector> WallNormalsByPattern;

	FVector FindWallNormal(UHazeActorSpawnPattern SpawnPattern, TSubclassOf<UActorComponent> WallCompClass, float Radius)
	{
		if (!WallNormalsByPattern.Contains(SpawnPattern))
			WallNormalsByPattern.Add(SpawnPattern, WallTracker::GetNearestWallNormal(SpawnPattern.WorldLocation, Radius, WallCompClass));

		return WallNormalsByPattern[SpawnPattern];
	}
}

namespace WallTracker
{
	FVector GetNearestWallNormal(FVector Location, float Radius, TSubclassOf<UActorComponent> WallCompClass = nullptr)
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_WorldStatic);
		Trace.UseSphereShape(Radius);
		FOverlapResultArray Result = Trace.QueryOverlaps(Location);
		float ClosestDistSqr = BIG_NUMBER;
		FVector BestNormal = FVector::ZeroVector;
		for (FOverlapResult Overlap : Result.OverlapResults)
		{
			if (!Overlap.bBlockingHit)
				continue;

			if (WallCompClass.IsValid())
			{
				if (Overlap.Actor == nullptr)
					continue;
				if (Overlap.Actor.GetComponentByClass(WallCompClass) == nullptr)
					continue;
			}		

			FVector DepenetrationDelta = Overlap.GetDepenetrationDelta(Trace.Shape, Location);
			float DistSqr = DepenetrationDelta.SizeSquared();
			if (DistSqr > ClosestDistSqr)
			 	continue;

			ClosestDistSqr = DistSqr;
			BestNormal = DepenetrationDelta.GetSafeNormal();
		}
		return BestNormal;
	}
}
