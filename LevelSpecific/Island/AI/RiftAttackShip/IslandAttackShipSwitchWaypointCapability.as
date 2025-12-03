// Coordinate movement in switching waypoint with team member.
class UIslandAttackShipSwitchWaypointCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"SwitchingWaypoint");
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90;

	AAIIslandAttackShip AttackShip;
	UIslandAttackShipSettings Settings;
	UBasicAIDestinationComponent DestComp;
	UBasicAITargetingComponent TargetComp;	

	USimpleMovementData Movement;
	
	FHazeRuntimeSpline Spline;
	FHazeAcceleratedRotator AccRotation;
	FRuntimeFloatCurve SpeedCurve;
	float MaxSpeed;
	
	bool bHasValidSpline = false;
	float CooldownTime = 0.0;
	float BumpCooldown = 0.7;
	bool bIsFollowerMoving = false; // ShouldActivate for follower
	bool bHasReachedDestination = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestComp = UBasicAIDestinationComponent::Get(Owner);
		TargetComp = UBasicAITargetingComponent::Get(Owner);
		AttackShip = Cast<AAIIslandAttackShip>(Owner);
		if (AttackShip.CurrentManager == nullptr)
		{
			IslandAttackShip::GetClosestManager(AttackShip, AttackShip.CurrentManager);
		}		
		AttackShip.CurrentManager.OnMoveStarted.AddUFunction(this, n"OnSwitchWaypointStarted");
		Settings = UIslandAttackShipSettings::GetSettings(Owner);
	}

	UFUNCTION()
	private void OnSwitchWaypointStarted()
	{
		AccRotation.Value = Owner.ActorRotation;

		// Add ignore actors to waypoint's visibility check. Not implemented.
		TArray<AHazeActor> IgnoreActors;
		IgnoreActors.Add(AttackShip);
		
		// Get next waypoint
		AIslandAttackShipScenepointActor BestWaypoint;
		IslandAttackShip::GetNextWaypoint(Owner, IgnoreActors, AttackShip.CurrentWaypoint, BestWaypoint);
		AttackShip.CurrentWaypoint = BestWaypoint;
		//CrumbClaimWaypoint(BestWaypoint);

		FIslandAttackShipPathPattern PathPattern;
		AttackShip.CurrentManager.GetCurrentPathPattern(PathPattern);

		// Create runtimespline for move trajectory
		// This, currently, does not consider walls or other obstacles
		Spline = FHazeRuntimeSpline();
		Spline.AddPoint(Owner.ActorLocation); // Start

		FVector TargetLocation = AttackShip.CurrentWaypoint.ActorLocation;
		FVector ToTargetLocation = (TargetLocation - Owner.ActorLocation);
		FVector ToTargetDir = ToTargetLocation.GetSafeNormal();
		FVector ToTargetLocationRightDir = FVector::UpVector.CrossProduct(ToTargetDir).GetSafeNormal();

		// Sample pattern for points. Approximates the curves in the pattern. Endpoints are the waypoints' actor location.
		float MaxDepth = PathPattern.MaxDepth;
		float MaxHeight = PathPattern.MaxHeight;
		for (int I = 1; I < 10; I++)
		{
			//float Alpha = AttackShip.CurrentManager.IsLeader(AttackShip) ? I * 0.1 : (1.0 - I * 0.1); // Leader forward, follower reverse
			float Alpha = I * 0.1;
			float RightOffset = PathPattern.DepthCurve.GetFloatValue(Alpha) * MaxDepth;
			float HeightOffset = PathPattern.HeightCurve.GetFloatValue(Alpha) * MaxHeight;
			FVector SplinePointLocation;
			SplinePointLocation = Owner.ActorLocation + (ToTargetLocation * I * 0.1);
			
			// Offset depth ()			
			SplinePointLocation += ToTargetLocationRightDir * RightOffset;
			SplinePointLocation.Z += AttackShip.CurrentManager.IsLeader(AttackShip) ? HeightOffset : -HeightOffset;
			Spline.AddPoint(SplinePointLocation);
		}		

		Spline.AddPoint(TargetLocation); // End
		
		//Spline.DrawDebugSpline(Duration = 10.0, Width = 2.0);
		//Debug::DrawDebugSphere(TargetLocation, 50, Duration = 10.0);
		
		SpeedCurve = PathPattern.SpeedCurve;
		MaxSpeed = PathPattern.MaxSpeed;

		DistanceAlongSpline = 0;
		bHasValidSpline = true;
		bIsFollowerMoving = true;
		bHasReachedDestination = false;
		if (Spline.GetLength() < SMALL_NUMBER)
		{
			bHasValidSpline = false;
			bIsFollowerMoving = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (AttackShip == nullptr)
			return false;
		if (AttackShip.CurrentManager == nullptr)
			return false;
		if (!IslandAttackShip::HasWaypointsInLevel())
			return false;
		if (!AttackShip.CurrentManager.HasTeam())
			return false;
		if (!AttackShip.CurrentManager.HasPathPatterns())
			return false;
		if (!AttackShip.CurrentManager.IsLeader(AttackShip) && !bIsFollowerMoving) // follow the leaders que
			return false;
		if (!AttackShip.CurrentManager.HasTeamFinishedEntry())
			return false;
		if (AttackShip.CurrentManager.IsLeader(AttackShip) && CooldownTime > Time::GameTimeSeconds)
			return false;
		if (AttackShip.bHasPilotDied)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (AttackShip.CurrentWaypoint == nullptr)
			return true;
		if(!bHasValidSpline)
			return true;
		if (bHasReachedDestination)
			return true;
		if (AttackShip.bHasPilotDied)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Get Pattern from Manager
		if (AttackShip.CurrentManager.IsLeader(Owner))
		{
			AttackShip.CurrentManager.AdvanceCurrentPathPatternIndex();
			AttackShip.CurrentManager.ReportStartMoving();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CooldownTime = Time::GameTimeSeconds + 5.0;

		AttackShip.CurrentManager.ReportStopMoving();
		bIsFollowerMoving = false;
	}

	float DistanceAlongSpline = 0;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Follow spline
		if(!bHasValidSpline)
			return;
		
		DistanceAlongSpline += MaxSpeed * SpeedCurve.GetFloatValue(DistanceAlongSpline/Spline.GetLength()) * DeltaTime;

		if (DistanceAlongSpline > Spline.GetLength() - 50)
		{
			DistanceAlongSpline = Math::Min(DistanceAlongSpline, Spline.GetLength());
			bHasReachedDestination = true;
			return;
		}

		float SplineAlpha = DistanceAlongSpline/Spline.GetLength();
		FVector NewLocation = Spline.GetLocation(SplineAlpha);		
		
		Owner.SetActorLocation(NewLocation);
	}

};