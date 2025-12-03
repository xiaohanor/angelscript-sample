enum ETraversalScenepointTrajectoryDirectionType
{
	LandingAndLaunching,
	LandingOnly,
	LaunchingOnly,
	MAX
}

// Traversal methods each decide which type of scene point they will use.
// The scene point sub classes contain the data needed for that method.
UCLASS(Abstract) 
class UTraversalScenepointComponent : UScenepointComponent
{
	access VisualizerReadable = private, UHazeScriptComponentVisualizer (inherited, readonly);

	default CooldownDuration = 5;

	// Height above traveral point which we assume we can clear (to pass over a railing etc)
	UPROPERTY(EditAnywhere)
	float TraversalHeight = 100.0;

	// Currently used by SimpleTraversal
	// Whether this TraversalScenepoint is used as a launch point, landing point, or both.
	UPROPERTY(EditAnywhere)
	ETraversalScenepointTrajectoryDirectionType TraversalLaunchType = ETraversalScenepointTrajectoryDirectionType::LandingAndLaunching;

	// Currently used by SimpleTraversal
	// Whether this TraversalScenepoint is locked from updating desination arcs.
	UPROPERTY(EditAnywhere)
	bool bIsLocked = false;

	UPROPERTY(VisibleAnywhere)
	TSubclassOf<UObject> UsedByMethod;

	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		if (!bIsLocked)
		{
			ATraversalAreaActorBase Area = Cast<ATraversalAreaActorBase>(Owner);
			if (Area != nullptr)
				Area.UpdateModifiedComponent(this);
		}
	}

	bool HasAnyDestinations() const 
	{
		return GetDestinationCount() > 0;
	}

	// Subclasses should override the below functions ---
	bool HasDestination(int DestinationIndex) const { return false; }
	int GetDestinationCount() const { return 0;	} 
	FVector GetDestination(int DestinationIndex) const { return WorldLocation; }
	AActor GetDestinationArea(int DestinationIndex) const {	return nullptr;	}
	bool IsAtDestination(int DestinationIndex, AHazeActor Actor) const { return false; }
	bool CanUseDestination(int DestinationIndex, AHazeActor User) const { return false; }
	void ClearDestinations() {}
	//---------------------------------------------------
}


namespace TraversalScenepoint
{
	FSphere GetBounds(TArray<UTraversalScenepointComponent> TraversalPoints)
	{
		FSphere Sphere;
		if (TraversalPoints.Num() == 0)
			return Sphere;

		// Use offset from first comp to reduce floating point rounding issues
		FVector BaseLoc = TraversalPoints[0].WorldLocation;
		FVector BoundsOffset = FVector::ZeroVector;
		for (UTraversalScenepointComponent Point : TraversalPoints)
		{
			BoundsOffset += Point.WorldLocation - BaseLoc;
		}
		BoundsOffset /= TraversalPoints.Num();
		Sphere.Center = BaseLoc + BoundsOffset;
		Sphere.W = 0.0;
		for (UTraversalScenepointComponent Point : TraversalPoints)
		{
			if (!Sphere.Center.IsWithinDist(Point.WorldLocation, Sphere.W))
				Sphere.W = Sphere.Center.Distance(Point.WorldLocation); 
		}
		return Sphere;
	}
}