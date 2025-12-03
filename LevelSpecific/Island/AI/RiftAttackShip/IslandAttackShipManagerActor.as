event void FOnMoveStarted();
event void FOnTeamWipedOut(AHazeActor LastTeamMember);

// Manages nearby attack ships to coordinate movement.
UCLASS(HideCategories = "Physics Debug Activation Cooking Tags LOD Collision Rendering Actor")
class AIslandAttackShipManagerActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "Scenepoint";
	default Billboard.WorldScale3D = FVector(2.0); 
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 100.0);

	UPROPERTY(DefaultComponent)
	UTextRenderComponent MarkerText;
	default MarkerText.IsVisualizationComponent = false;
	default MarkerText.Text = FText::FromString("AttackShipManager");
	default MarkerText.TextRenderColor = FColor::Silver;
	default MarkerText.RelativeLocation = FVector(0.0, 0.0, 200.0);
	default MarkerText.bHiddenInGame = true;
	default MarkerText.WorldSize = 75.0;
	default MarkerText.HorizontalAlignment = EHorizTextAligment::EHTA_Center;	

	UPROPERTY(DefaultComponent)
	UIslandAttackShipManagerActorVisualizerComponent VisualizeComponent;

	UPROPERTY(EditAnywhere)
	bool bShowVisualizer = false;

	UPROPERTY(EditAnywhere, Meta = (ArrayClamp="Paths"))
	int VisualizedPatternIndex = 0;
#endif	

	
	TArray<AHazeActor> TeamMembers;

	// Testing simple runtime curves. Might switch to using spline actors placed in level.
	UPROPERTY(EditAnywhere)
	TArray<FIslandAttackShipPathPattern> Paths;
	
	private AHazeActor LastTeamMember;
	private int CurrentPathIndex = -1;
	private bool bIsMoving = false;	


	UPROPERTY()
	FOnMoveStarted OnMoveStarted;
	
	UPROPERTY()
	FOnTeamWipedOut OnTeamWipedOut;
	

	// Let other ships about coordinated movement and about which pattern to use. May pass an invalid index.
	void ReportStartMoving()
	{
		if (bIsMoving)
			return;
		bIsMoving = true;
		OnMoveStarted.Broadcast();
	}

	void ReportStopMoving()
	{
		bIsMoving = false;
	}

	void ReportToManager(AHazeActor TeamMember)
	{
		TeamMembers.AddUnique(TeamMember);
	}

	void ReportUnspawned(AHazeActor TeamMember)
	{
		// Members only.
		if (!TeamMembers.Contains(TeamMember))
			return;

		TeamMembers.RemoveSingleSwap(TeamMember);
		if (TeamMembers.IsEmpty())
		{
			OnTeamWipedOut.Broadcast(TeamMember);
			LastTeamMember = nullptr;
		}
	}

	bool TryGetPathPattern(int8 Index, FIslandAttackShipPathPattern& OutPathPattern)
	{
		if (Paths.IsEmpty() || Paths.Num() < Index + 1)
			return false;

		OutPathPattern = Paths[Index];
		
		return true;
	}

	void SetNextPathPattern(int Index)
	{
		check(!Paths.IsEmpty() && Index >= 0 && Index < Paths.Num());
		CurrentPathIndex = Index;
	}

	// Increment current path index, wraps from 0 once it hits the end of the list.
	void AdvanceCurrentPathPatternIndex()
	{
		check(!Paths.IsEmpty());
		CurrentPathIndex++;
		if (CurrentPathIndex >= Paths.Num())
			CurrentPathIndex = 0; 
	}

	void GetCurrentPathPattern(FIslandAttackShipPathPattern& OutPathPattern)
	{
		check(!Paths.IsEmpty() && CurrentPathIndex >= 0 && CurrentPathIndex < Paths.Num());

		OutPathPattern = Paths[CurrentPathIndex];
	}

	// Leader is number one.
	bool IsLeader(AHazeActor TeamMember)
	{
		if (!TeamMembers.IsEmpty() && TeamMembers[0] == TeamMember)
			return true;

		return false;
	}
	
	bool HasPathPatterns()
	{
		return !Paths.IsEmpty();
	}

	// You are not alone. Can include members where the pilot is dead and the ship is crashing.
	bool HasTeam()
	{
		return TeamMembers.Num() > 1;
	}

	// 
	bool HasLivingTeamMember(AHazeActor TeamMember)
	{
		if (!HasTeam())
			return false;

		for (AHazeActor Member : TeamMembers)
		{
			if (Member == TeamMember)
				continue;

			if (!Cast<AAIIslandAttackShip>(Member).bHasPilotDied)
				return true;
		}
		return false;
	}

	bool HasTeamFinishedEntry()
	{
		for (AHazeActor Member : TeamMembers)
		{
			if (!Cast<AAIIslandAttackShip>(Member).bHasFinishedEntry)
				return false;
		}
		return true;
	}

	bool IsSwitchingWaypoint()
	{
		return bIsMoving;
	}

	void SetMarkLastTeamMember(AHazeActor TeamMember)
	{
		LastTeamMember = TeamMember;
	}

	bool IsLastTeamMember(AHazeActor TeamMember)
	{
		devCheck(TeamMember != nullptr);
		return LastTeamMember == TeamMember;
	}
}

struct FIslandAttackShipPathPattern
{
	FIslandAttackShipPathPattern()
	{
		SpeedCurve.AddDefaultKey(0.0, 0.1);
		SpeedCurve.AddDefaultKey(0.5, 1.0);
		SpeedCurve.AddDefaultKey(1.0, 0.0);

		HeightCurve.AddDefaultKey(0.0, 0.0);
		HeightCurve.AddDefaultKey(1.0, 0.0);

		DepthCurve.AddDefaultKey(0.0, 0.0);
		DepthCurve.AddDefaultKey(1.0, 0.0);
	}
	
	UPROPERTY()
	FRuntimeFloatCurve SpeedCurve;
	
	UPROPERTY()
	FRuntimeFloatCurve HeightCurve;

	UPROPERTY()
	FRuntimeFloatCurve DepthCurve;

	UPROPERTY()
	float MaxSpeed = 1000.0;

	UPROPERTY()
	float MaxDepth = 0.0;

	UPROPERTY()
	float MaxHeight = 0.0;
}

#if EDITOR
class UIslandAttackShipManagerActorVisualizerComponent : UActorComponent
{
}

class UIslandAttackShipManagerActorVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandAttackShipManagerActorVisualizerComponent;

	float DistanceAlongSpline = 0.0;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		AIslandAttackShipManagerActor Manager = Cast<AIslandAttackShipManagerActor>(Component.Owner);
		if (Manager == nullptr)
			return;

		if (!Manager.bShowVisualizer)
			return;
		
		// For prototype, only supports the two placed waypoints int the example scenario.
		TListedActors<AIslandAttackShipScenepointActor> Waypoints;
		if (Waypoints.Num() != 2)
			return;

		if (Manager.Paths.IsEmpty())
			return;

		FIslandAttackShipPathPattern PathPattern = Manager.Paths[Manager.VisualizedPatternIndex];
		
		// Get next waypoint
		AIslandAttackShipScenepointActor WaypointStart = Waypoints[0];
		AIslandAttackShipScenepointActor WaypointEnd = Waypoints[1];

		FHazeRuntimeSpline ForwardSpline;
		ConstructRuntimeSpline(WaypointStart, WaypointEnd, PathPattern, false, ForwardSpline);
		FHazeRuntimeSpline ReverseSpline;
		ConstructRuntimeSpline(WaypointEnd, WaypointStart, PathPattern, true, ReverseSpline);
		
		DrawSpline(ForwardSpline, PathPattern);
		DrawSpline(ReverseSpline, PathPattern);
	}

	void ConstructRuntimeSpline(AIslandAttackShipScenepointActor Start, AIslandAttackShipScenepointActor End, FIslandAttackShipPathPattern PathPattern, bool bInverseHeightCurve, FHazeRuntimeSpline& OutSpline)
	{
		// Create runtimespline for move trajectory
		// This, currently, does not consider walls or other obstacles
		
		OutSpline = FHazeRuntimeSpline();
		OutSpline.AddPoint(Start.ActorLocation); // Start

		FVector TargetLocation = End.ActorLocation;
		FVector ToTargetLocation = (TargetLocation - Start.ActorLocation);
		FVector ToTargetDir = ToTargetLocation.GetSafeNormal();
		FVector ToTargetLocationRightDir = FVector::UpVector.CrossProduct(ToTargetDir).GetSafeNormal();

		// Sample pattern for points. Approximates the curves in the pattern. Endpoints are the waypoints' actor location.
		float MaxDepth = PathPattern.MaxDepth;
		float MaxHeight = bInverseHeightCurve ? -PathPattern.MaxHeight : PathPattern.MaxHeight;
		for (int I = 1; I < 10; I++)
		{
			//float Alpha = AttackShip.CurrentManager.IsLeader(AttackShip) ? I * 0.1 : (1.0 - I * 0.1); // Leader forward, follower reverse
			float Alpha = I * 0.1;
			float RightOffset = PathPattern.DepthCurve.GetFloatValue(Alpha) * MaxDepth;
			float HeightOffset = PathPattern.HeightCurve.GetFloatValue(Alpha) * MaxHeight;
			FVector SplinePointLocation;
			SplinePointLocation = Start.ActorLocation + (ToTargetLocation * I * 0.1);
			
			// Offset depth ()
			SplinePointLocation += ToTargetLocationRightDir * RightOffset;
			SplinePointLocation.Z += HeightOffset; // Use negative offset for the other way around
			OutSpline.AddPoint(SplinePointLocation);
		}		

		OutSpline.AddPoint(TargetLocation); // End
	}

	void DrawSpline(FHazeRuntimeSpline InSpline, FIslandAttackShipPathPattern PathPattern, int NumSegments = 150, float Width = 10, float Duration = 0.0, bool bDrawInForeground = false)
	{
		if(InSpline.Points.Num() < 2)
			return;

		// start spline point
		Debug::DrawDebugPoint(InSpline.Points[0], Width * 3, FLinearColor::Green, Duration, bDrawInForeground);

		// end spline point
		Debug::DrawDebugPoint(InSpline.Points.Last(), Width * 3, FLinearColor::Blue, Duration, bDrawInForeground);

		// draw all spline points that we've assigned
		for(int i = 1; i < InSpline.Points.Num() - 1; i++)
			Debug::DrawDebugPoint(InSpline.Points[i], Width, FLinearColor::Purple, Duration, bDrawInForeground);

		// Find 150 uniformerly distributed locations on the spline
		TArray<FVector> Locations;
		InSpline.GetLocations(Locations, NumSegments);

		// Draw all locations that we've found on the spline
		for(FVector L : Locations)
			Debug::DrawDebugPoint(L, Width, FLinearColor::Black, Duration, bDrawInForeground);

		// Draw a location moving along the spline based on elasped time
		//float TotalTime = 
		//Log("" + Time::GetGameTimeSeconds());
		//Log("" + Time::GetGlobalWorldDeltaSeconds());
		
		DistanceAlongSpline += PathPattern.MaxSpeed * PathPattern.SpeedCurve.GetFloatValue(DistanceAlongSpline/InSpline.GetLength()) * Time::GetGlobalWorldDeltaSeconds(); // TODO: speed setting
		if (DistanceAlongSpline >= InSpline.GetLength() - 10)
			DistanceAlongSpline -= InSpline.GetLength();
		float Alpha = DistanceAlongSpline/InSpline.GetLength();
		Log("" + Alpha);
		Debug::DrawDebugPoint(InSpline.GetLocation(Alpha), Width * 3, FLinearColor::White, Duration, bDrawInForeground);
	}
};
#endif