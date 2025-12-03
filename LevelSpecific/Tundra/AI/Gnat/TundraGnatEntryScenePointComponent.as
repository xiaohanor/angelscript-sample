struct FTundraGnatClimbData
{
	UPROPERTY(BlueprintHidden, NotVisible)
	FVector Location;

	UPROPERTY(BlueprintHidden, NotVisible)
	FVector UpVector;
}

class UTundraGnatEntryScenepointComponent : UScenepointComponent
{
	default Radius = 200.0;
	float LastUseTime;
	TArray<UTundraGnapeEntryWayPoint> Waypoints;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetSortedWaypoints(Waypoints);
	}

	void Use(AHazeActor Actor) override
	{
		Super::Use(Actor);
		LastUseTime = Time::GameTimeSeconds;
	}

	private void GetSortedWaypoints(TArray<UTundraGnapeEntryWayPoint>& OutWaypoints)
	{
		TArray<UTundraGnapeEntryWayPoint> AllWaypoints;
		Owner.GetComponentsByClass(AllWaypoints);

		for (UTundraGnapeEntryWayPoint Waypoint : AllWaypoints)
		{
			if (Waypoint.ScenepointSocket == AttachSocketName)
				OutWaypoints.Add(Waypoint);
		}
		OutWaypoints.Sort();
	}

#if EDITOR
	void DrawClimbSpline(UHazeScriptComponentVisualizer Visualizer)
	{
		TArray<UTundraGnapeEntryWayPoint> CurWayPoints;
		GetSortedWaypoints(CurWayPoints);

		TArray<FVector> Points;
		TArray<FVector> UpDirs;
		Points.Add(WorldLocation);
		UpDirs.Add(UpVector);
		for (UTundraGnapeEntryWayPoint Waypoint : CurWayPoints)
		{
			Points.Add(Waypoint.WorldLocation);
			UpDirs.Add(Waypoint.UpVector);
		}

		FHazeRuntimeSpline Spline;
		Spline.SetPointsAndUpDirections(Points, UpDirs);
		TArray<FVector> SplineLocs;
		Spline.GetLocations(SplineLocs, 150);
		for (int i = 1; i < SplineLocs.Num(); i++)
		{
			Visualizer.DrawLine(SplineLocs[i-1], SplineLocs[i], FLinearColor::Purple, 10.0);
			Visualizer.DrawLine(SplineLocs[i], SplineLocs[i] + Spline.GetUpDirection(i / float(SplineLocs.Num())) * 40.0, FLinearColor::DPink, 4.0);
		}
	}
#endif
}

class UTundraGnapeEntryWayPoint : USceneComponent
{
	FName ScenepointSocket;
	int Order;

	int opCmp(UTundraGnapeEntryWayPoint Other) const
	{
		if (Order > Other.Order)
			return 1;
		else if (Order < Other.Order)
			return -1;
		else
			return 0;
	}

	UTundraGnatEntryScenepointComponent	GetScenepoint()
	{
		TArray<UTundraGnatEntryScenepointComponent> Entrypoints;
		Owner.GetComponentsByClass(Entrypoints);
		for (UTundraGnatEntryScenepointComponent Point : Entrypoints)
		{
			if (Point.AttachSocketName == ScenepointSocket)
				return Point;
		}
		return nullptr;
	}
}

#if EDITOR
class UTundraGnapeEntryWaypointComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTundraGnapeEntryWayPoint;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UTundraGnapeEntryWayPoint Waypoint = Cast<UTundraGnapeEntryWayPoint>(Component);
        if (Waypoint == nullptr)
            return;
		UHazeSkeletalMeshComponentBase Mesh = UHazeSkeletalMeshComponentBase::Get(Waypoint.Owner);
		if (Mesh == nullptr)
			return;
		UTundraGnatEntryScenepointComponent Scenepoint = Waypoint.GetScenepoint();
		if (Scenepoint == nullptr)
			return;	
		Scenepoint.DrawClimbSpline(this);
    }
}

class UTundraGnatEntryScenepointComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTundraGnatEntryScenepointComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UTundraGnatEntryScenepointComponent Scenepoint = Cast<UTundraGnatEntryScenepointComponent>(Component);
        if (Scenepoint == nullptr)
            return;
		Scenepoint.DrawClimbSpline(this);
    }
}
#endif

