namespace Wallclimbing
{
	AWallclimbingNavigationVolume GetNavigationVolume(FVector Location, float Radius)
	{
		UWallclimbingNavigationVolumeSet Set = Game::GetSingleton(UWallclimbingNavigationVolumeSet);
		for (AVolume Volume : Set.Volumes)
		{
			if (Volume.EncompassesPoint(Location, Radius))
				return Cast<AWallclimbingNavigationVolume>(Volume);
		}
		return nullptr;
	}

	bool FindLocationOnNavmesh(AHazeActor Actor, FVector Location, FVector& OutNavmeshLocation, float UserRadius = 0.0, float VerticalTolerance = 200.0, float HorizontalTolerance = 200.0, FVector WantedNormal = FVector::ZeroVector)
	{
		UWallclimbingComponent WallclimbingComp	= UWallclimbingComponent::Get(Actor);
		if ((WallclimbingComp == nullptr) || (WallclimbingComp.Navigation == nullptr))
			return false;

		return WallclimbingComp.Navigation.FindLocationOnNavmesh(Location, OutNavmeshLocation, UserRadius, VerticalTolerance, HorizontalTolerance, WantedNormal);
	}

	bool FindClosestNavmeshPoly(AHazeActor Actor, FVector Location, FWallclimbingNavigationFace& OutPoly, float UserRadius = 0.0, float VerticalTolerance = 200.0, float HorizontalTolerance = 200.0, FVector WantedNormal = FVector::ZeroVector)
	{
		UWallclimbingComponent WallclimbingComp	= UWallclimbingComponent::Get(Actor);
		if ((WallclimbingComp == nullptr) || (WallclimbingComp.Navigation == nullptr))
			return false;

		return WallclimbingComp.Navigation.FindClosestNavmeshPoly(Location, OutPoly, UserRadius, VerticalTolerance, HorizontalTolerance, WantedNormal);
	}

	bool HasStraightPath(AHazeActor Actor, FVector Start, FVector Destination, float OwnerSize = 0.0, float VerticalTolerance = 200.0, float HorizontalTolerance = 200.0, FVector StartNormal = FVector::ZeroVector, FVector DestinationNormal = FVector::ZeroVector, float AllowedOffsetFactor = 0.25)
	{
		UWallclimbingComponent WallclimbingComp	= UWallclimbingComponent::Get(Actor);
		if ((WallclimbingComp == nullptr) || (WallclimbingComp.Navigation == nullptr))
			return false;
		TArray<FWallClimbingPathNode> Path;
		if (!WallclimbingComp.Navigation.FindPath(Start, StartNormal, Destination, DestinationNormal, OwnerSize, VerticalTolerance, HorizontalTolerance, Path))
			return false;
		if(Path.Num() < 3)
			return true;

		// TODO: Unfold
		// FTransform UnfoldedTransform = FTransform(FQuat::MakeFromZY(Path.Normal, EdgeRight - EdgeLeft), (EdgeRight + EdgeLeft) * 0.5);
		for(int i = 1; i < Path.Num()-1; i++)
		{
			FVector ClosestPoint = Math::ClosestPointOnInfiniteLine(Start, Destination, Path[i].Location);
			if(!ClosestPoint.IsWithinDist(Path[i].Location, OwnerSize * AllowedOffsetFactor))
				return false;
		}
		return true;
	}
}


