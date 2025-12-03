class USkylineGeckoFloorProbeManager : UObject
{

}

class USkylineGeckoFloorProbeComponent : UActorComponent
{
	FVector SplineUp = FVector::ZeroVector;
	FVector NearestUp = FVector::ZeroVector;
	FVector DefaultUp = FVector::UpVector;

	FVector GetFloorUp() const
	{
		if (NearestUp.IsNormalized())
			return NearestUp;

		if (SplineUp.IsNormalized())
			return SplineUp;

		return DefaultUp;	
	}
}

class USkylineGeckoFloorProbeCapability : UHazeCapability
{
	// Control side only
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"FloorProbe");

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 150; // After any path following capability, but before movement

	USkylineGeckoFloorProbeComponent ProbeComp;
	UBasicAIRuntimeSplineComponent SplineComp;
	UBasicAIDestinationComponent DestinationComp;
	UWallclimbingComponent WallclimbingComp;
	UPathfollowingSettings PathingSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ProbeComp = USkylineGeckoFloorProbeComponent::GetOrCreate(Owner);
		SplineComp = UBasicAIRuntimeSplineComponent::GetOrCreate(Owner);
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		WallclimbingComp = UWallclimbingComponent::GetOrCreate(Owner);
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return HasControl();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !HasControl();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Reset
		ProbeComp.NearestUp = FVector::ZeroVector;
		ProbeComp.SplineUp = FVector::ZeroVector;

		// Trust in spline from pathfinding
		bool bUseSpline = SplineComp.HasSpline() && !PathingSettings.bIgnorePathfinding;

		if (DestinationComp.MoveFailed() || !bUseSpline)	
		{
			// Cannot find path, find closest upvector instead
			FWallclimbingNavigationFace Poly;
			if (Wallclimbing::FindClosestNavmeshPoly(Owner, Owner.ActorCenterLocation, Poly, 0.0, 200.0, 200.0))
				ProbeComp.NearestUp = Poly.Normal;
		}
		
		if (bUseSpline)
			ProbeComp.SplineUp = SplineComp.Spline.GetUpDirectionAtDistance(SplineComp.DistanceAlongSpline);

		ProbeComp.DefaultUp = -WallclimbingComp.PreferredGravity;

#if EDITOR
		// ProbeComp.bHazeEditorOnlyDebugBool = true;
		if (ProbeComp.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ProbeComp.GetFloorUp() * 1000, FLinearColor::DPink, 5.0);
		}
#endif
	}
}
