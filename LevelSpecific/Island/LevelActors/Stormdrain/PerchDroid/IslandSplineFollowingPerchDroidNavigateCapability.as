class UIslandSplineFollowingPerchDroidNavigateCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AIslandSplineFollowingPerchDroid Droid;
	UBasicAIDestinationComponent DestComp;
	UHoverPerchComponent HoverPerchComp;

	AIslandSplineFollowingPerchDroidTacticalWaypoint Waypoint;

	FRuntimeFloatCurve Speed;	
	default Speed.AddDefaultKey(0.0, 0.1);
	default Speed.AddDefaultKey(0.5, 1.0);
	default Speed.AddDefaultKey(1.0, 0.1);

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Rotation;
	default Rotation.AddDefaultKey(0.0, 0.0);
	default Rotation.AddDefaultKey(1.0, 1.0);


	FHazeRuntimeSpline Spline;
	
	bool bHasValidSpline = false;
	float CooldownTime = 0.0;
	float BumpCooldown = 0.7;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		//MoveToComp.DefaultSettings = BasicAIFlyingIgnorePathfindingMoveToSettings;
		DestComp = UBasicAIDestinationComponent::Get(Owner);
		HoverPerchComp = UHoverPerchComponent::Get(Owner);
		Droid = Cast<AIslandSplineFollowingPerchDroid>(Owner);			
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Droid == nullptr)
			return false;
		if (!Droid.bHasFinishedEntrance)
			return false;
		if (Droid.RiderActor == nullptr)
			return false;
		if (!Droid.bCanFreeRoamChaseTarget && !IslandSplineFollowingPerchDroid::HasTacticalWaypointsInLevel())
			return false;
		if (CooldownTime > Time::GameTimeSeconds)
			return false;
		if (!Droid.RiderActor.TargetingComponent.HasValidTarget())
			return false;
		if(Time::GetGameTimeSince(HoverPerchComp.TimeLastBumpedOtherPerch) < BumpCooldown)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Droid.bCanFreeRoamChaseTarget && Waypoint == nullptr)
			return true;
		if(!bHasValidSpline)
			return true;
		if (CooldownTime > Time::GameTimeSeconds)
			return true;
		if(Time::GetGameTimeSince(HoverPerchComp.TimeLastBumpedOtherPerch) < BumpCooldown)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{	
		if (!HasControl())
			return;

		// TODO: check for not intersecting team members

		// Add ignore actors to waypoint's visibility check
		TArray<AHazeActor> IgnoreActors;
		IgnoreActors.Add(Droid);		
		UHoverPerchPlayerComponent PlayerPerchComp = UHoverPerchPlayerComponent::Get(Droid.RiderActor.TargetingComponent.Target);
		if (PlayerPerchComp != nullptr && PlayerPerchComp.PerchActor != nullptr)
		{
			IgnoreActors.Add(PlayerPerchComp.PerchActor);
		}

		// Try find a waypoint
		AIslandSplineFollowingPerchDroidTacticalWaypoint BestWaypoint;
		if (Droid.WaypointPickingMode == IslandSplineFollowingPerchDroid::EWaypointPicking::PickDefault)
			IslandSplineFollowingPerchDroid::GetBestTacticalWaypoint(Owner, Cast<AHazeActor>(Droid.RiderActor.TargetingComponent.Target), IgnoreActors, BestWaypoint);
		else if (Droid.WaypointPickingMode == IslandSplineFollowingPerchDroid::EWaypointPicking::PickClosestToTarget)
			IslandSplineFollowingPerchDroid::GetTargetsClosestTacticalWaypoint(Owner, Cast<AHazeActor>(Droid.RiderActor.TargetingComponent.Target), IgnoreActors, BestWaypoint);
		CrumbClaimWaypoint(BestWaypoint);

		// Try set TargetLocation
		FVector TargetLocation;
		if (Waypoint != nullptr)
		{
			TargetLocation = Waypoint.ActorLocation; 			
		}
		else if (Droid.bCanFreeRoamChaseTarget)
		{
			// Keep distance from target
			FVector FromTargetActorDir = (Owner.ActorLocation - Droid.RiderActor.TargetingComponent.Target.ActorLocation).GetSafeNormal();
			TargetLocation = Droid.RiderActor.TargetingComponent.Target.ActorLocation + FromTargetActorDir * 2000;
		
			// Check for obstructed view from target location
			FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::Visibility);
			Trace.UseLine();
			Trace.IgnoreActor(Owner);
			Trace.IgnoreActor(Droid.RiderActor.TargetingComponent.Target);
			Trace.IgnoreActors(IgnoreActors);

			FHitResult Obstruction = Trace.QueryTraceSingle(TargetLocation, Droid.RiderActor.TargetingComponent.Target.ActorCenterLocation);
			FHitResult ObstructionInTargetLocationDir = Trace.QueryTraceSingle(Owner.ActorLocation, TargetLocation);
			if (Obstruction.bBlockingHit || ObstructionInTargetLocationDir.bBlockingHit)
			{
				CooldownTime = 1.0; // Deactivates capability.
				return;
			}				
		}
		else
		{
			CooldownTime = 1.0; // Deactivates capability.
			return;
		}

		// Create runtimespline for move trajectory
		// This, currently, does not consider walls or other obstacles
		CrumbBuildSpline(TargetLocation);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CooldownTime = Time::GameTimeSeconds + Math::RandRange(Droid.MovementCooldownMin, Droid.MovementCooldownMax);
	}

	float DistanceAlongSpline = 0;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Follow spline
		if(!bHasValidSpline)
			return;

		DistanceAlongSpline += 1000 * Speed.GetFloatValue(DistanceAlongSpline/Spline.GetLength()) * DeltaTime; // TODO: speed setting

		if (DistanceAlongSpline > Spline.GetLength() - 50)
		{
			CooldownTime = Time::GameTimeSeconds + 1.0; // Will deactivate capability.
			return;
		}

		float SplineAlpha = DistanceAlongSpline/Spline.GetLength();
		FVector NewLocation = Spline.GetLocation(SplineAlpha);		
		FVector NewUpVector = Spline.GetUpDirection(SplineAlpha);
		FQuat QuatAtDistance = Spline.GetQuat(SplineAlpha);

		FQuat NewRotation = FQuat::Slerp(Owner.ActorRotation.Quaternion(), FQuat::MakeFromZX(NewUpVector, QuatAtDistance.ForwardVector), DeltaTime);
		
		Owner.SetActorLocationAndRotation(NewLocation, NewRotation);
	}

	UFUNCTION(CrumbFunction)
	void CrumbClaimWaypoint(AIslandSplineFollowingPerchDroidTacticalWaypoint BestWaypoint)
	{
		if (Waypoint != nullptr && Waypoint != BestWaypoint)
			Waypoint.Release();
		if (BestWaypoint != nullptr)
		{
			BestWaypoint.Hold(Owner);
			Waypoint = BestWaypoint;
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbBuildSpline(FVector TargetLocation)
	{
		Spline = FHazeRuntimeSpline();
		Spline.AddPoint(Owner.ActorLocation); // Start

		// If destination is further away, add some curvature
		FVector ToTargetLocation = (TargetLocation - Owner.ActorLocation);
		if (ToTargetLocation.SizeSquared() > 1000*1000) // Minimum distance
		{
			FVector InterPoint = Owner.ActorLocation + ToTargetLocation * 0.75;
			InterPoint.Z = Owner.ActorLocation.Z + (TargetLocation.Z - Owner.ActorLocation.Z) * 0.33; // Height offset
			Spline.AddPoint(InterPoint);
		}		
		
		Spline.AddPoint(TargetLocation); // End
		
		//Spline.DrawDebugSpline(Duration = 10.0, Width = 2.0);
		//Debug::DrawDebugSphere(TargetLocation, 50, Duration = 10.0);
		
		DistanceAlongSpline = 0;
		bHasValidSpline = true;
		if (Spline.GetLength() < SMALL_NUMBER)
			bHasValidSpline = false;
	}
};