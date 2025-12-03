UCLASS(Abstract)
class ASkylineBossSplineHub : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.Mobility = EComponentMobility::Static;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Billboard;
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 100.0);
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	/**
	 * What paths connect to this hub?
	 * 0: Center
	 * 1: Right
	 * 2: Left
	 */
	UPROPERTY(EditInstanceOnly)
	TArray<ASkylineBossSpline> Paths;

	UPROPERTY(EditInstanceOnly)
	TArray<ASkylineBossSplineHub> ConnectedHubs;

	UPROPERTY(EditInstanceOnly)
	const bool bIsCenterHub = false;

	UPROPERTY(EditInstanceOnly)
	ARespawnPoint RespawnPointAfterRise;

	UPROPERTY(EditInstanceOnly)
	ARespawnPoint RespawnPointAfterFall;

	float SortDistance = -1;


	UFUNCTION(BlueprintCallable)
	ASkylineBossSpline GetSplineConnectedToHub(ASkylineBossSplineHub Hub)
	{
		if (Hub == nullptr)
		{
			devError(f"Hub was invalid.");
			return nullptr;
		}

		for (auto Spline : Paths)
		{
			if (Hub.Paths.Contains(Spline))
				return Spline;
		}

		devError(f"Hub \"{Name}\" and \"{Hub.Name}\" are not connected.");
		return nullptr;
	}

	UFUNCTION(BlueprintCallable)
	TArray<USkylineBossFootTargetComponent> GetOrderedFootTargets(ASkylineBossSpline FromSpline)
	{
		TArray<USkylineBossFootTargetComponent> FootTargets;
		FootTargets.SetNumZeroed(3);

		int RightSplineIndex = Paths.FindIndex(FromSpline);
		if (RightSplineIndex < 0)
		{
			devError(f"Supplied spline is not connected to this hub.");
			return FootTargets;
		}

		int LeftSplineIndex = Math::WrapIndex(RightSplineIndex - 1, 0, Paths.Num());
		int CenterSplineIndex = Math::WrapIndex(RightSplineIndex + 1, 0, Paths.Num());

		// Ordering is left, right, center, where the right is the spline we're coming from
		//  it depends on the ordering of the tripod legs, it all makes sense... I'm not crazy, you are.
		TArray<ASkylineBossSpline> OrderedPaths;
		OrderedPaths.Add(Paths[LeftSplineIndex]);
		OrderedPaths.Add(Paths[RightSplineIndex]);
		OrderedPaths.Add(Paths[CenterSplineIndex]);

		// Figure out whether the start or end is connected to the hub
		//  and then get the first/last foot target depending on that
		for (int i = 0; i < OrderedPaths.Num(); ++i)
		{
			auto Path = OrderedPaths[i];

			bool bIsStartingPoint = false;
			GetClosestSplineEndIndex(Path.Spline, ActorLocation, bIsStartingPoint);

			if (Path.FootTargets.Num() == 0)
			{
				devError(f"Path contained no foot targets.");
				continue;
			}

			if (bIsStartingPoint)
				FootTargets[i] = Path.FootTargets[0];
			else
				FootTargets[i] = Path.FootTargets.Last();
		}

		return FootTargets;
	}

	int GetClosestSplineEndIndex(UHazeSplineComponent Spline, FVector Location, bool&out OutIsStartPoint)
	{
		OutIsStartPoint = false;

		FVector StartPointWorldLocation = Spline.WorldTransform.TransformPosition(Spline.SplinePoints[0].RelativeLocation);
		FVector EndPointWorldLocation = Spline.WorldTransform.TransformPosition(Spline.SplinePoints.Last().RelativeLocation);

		if (Location.DistSquared(StartPointWorldLocation) < Location.DistSquared(EndPointWorldLocation))
		{
			OutIsStartPoint = true;
			return 0;
		}	

		return Spline.SplinePoints.Num() - 1;
	}

	int opCmp(ASkylineBossSplineHub Other) const
	{
		check(SortDistance >= 0);
		check(Other.SortDistance >= 0);

		if(SortDistance > Other.SortDistance)
			return 1;
		else
			return -1;
	}
};

namespace SkylineBoss
{
	TArray<ASkylineBossSplineHub> GetAllHubs()
	{
		return TListedActors<ASkylineBossSplineHub>().Array;
	}

	TArray<ASkylineBossSplineHub> GetAllHubsSortedByDistanceTo(FVector Location)
	{
		TArray<ASkylineBossSplineHub> SortedHubs = GetAllHubs();

		for(ASkylineBossSplineHub Hub : SortedHubs)
			Hub.SortDistance = Hub.ActorLocation.DistXY(Location);

		SortedHubs.Sort();
		return SortedHubs;
	}

	ASkylineBossSplineHub GetClosestHubTo(FVector Location)
	{
		ASkylineBossSplineHub Closest = nullptr;
		float ClosestHorizontalDistance = BIG_NUMBER;

		TArray<ASkylineBossSplineHub> AllHubs = GetAllHubs();
		for(ASkylineBossSplineHub Hub : AllHubs)
		{
			const float HorizontalDistance = Hub.ActorLocation.DistXY(Location);
			if(HorizontalDistance < ClosestHorizontalDistance)
			{
				Closest = Hub;
				ClosestHorizontalDistance = HorizontalDistance;
			}
		}

		return Closest;
	}

	ASkylineBossSplineHub GetBestHubForFall(ASkylineBossSplineHub CurrentHub, ASkylineBossSplineHub PreviousHub)
	{
		auto SortedHubs = GetAllHubsSortedByDistanceTo(CurrentHub.ActorLocation);
		for(int i = 1; i < SortedHubs.Num(); i++)
		{
			if(SortedHubs[i] == PreviousHub)
				continue;

			return SortedHubs[i];
		}

		return nullptr;
	}
}