class UIslandAttackShipNavigateCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90;

	AAIIslandAttackShip AttackShip;
	UIslandAttackShipSettings Settings;
	UBasicAIDestinationComponent DestComp;
	UBasicAITargetingComponent TargetComp;	

	USimpleMovementData Movement;

	FRuntimeFloatCurve Speed;	
	default Speed.AddDefaultKey(0.0, 0.1);
	default Speed.AddDefaultKey(0.5, 1.0);
	default Speed.AddDefaultKey(1.0, 0.0);

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Rotation;
	default Rotation.AddDefaultKey(0.0, 0.0);
	default Rotation.AddDefaultKey(1.0, 1.0);


	FHazeRuntimeSpline Spline;
	FHazeAcceleratedRotator AccRotation;
	
	bool bHasValidSpline = false;
	float CooldownTime = 0.0;
	float BumpCooldown = 0.7;

	bool bHasReachedFirstWaypoint = false; // temp

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestComp = UBasicAIDestinationComponent::Get(Owner);
		TargetComp = UBasicAITargetingComponent::Get(Owner);
		AttackShip = Cast<AAIIslandAttackShip>(Owner);
		Settings = UIslandAttackShipSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (AttackShip == nullptr)
			return false;
		if (AttackShip.CurrentManager.IsSwitchingWaypoint())
			return false;
		if (AttackShip.CurrentManager.HasTeam() && bHasReachedFirstWaypoint)
			return false;
		if (!IslandAttackShip::HasWaypointsInLevel())
			return false;
		if (CooldownTime > Time::GameTimeSeconds)
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
		if (CooldownTime > Time::GameTimeSeconds)
			return true;
		if (AttackShip.bHasPilotDied)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(CapabilityTags::Movement, this);

		AccRotation.Value = Owner.ActorRotation;

		// Add ignore actors to waypoint's visibility check
		TArray<AHazeActor> IgnoreActors;
		IgnoreActors.Add(AttackShip);
		
		// Try find a waypoint
		AIslandAttackShipScenepointActor BestWaypoint;
		IslandAttackShip::GetNextWaypoint(Owner, IgnoreActors, AttackShip.CurrentWaypoint, BestWaypoint);
		AttackShip.CurrentWaypoint = BestWaypoint;
		//CrumbClaimWaypoint(BestWaypoint);

		// Try set TargetLocation
		FVector TargetLocation;
		if (AttackShip.CurrentWaypoint != nullptr)
		{
			TargetLocation = AttackShip.CurrentWaypoint.ActorLocation; 			
		}		
		else
		{
			CooldownTime = 1.0; // Deactivates capability.
			return;
		}

		// Create runtimespline for move trajectory
		// This, currently, does not consider walls or other obstacles
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

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CooldownTime = Time::GameTimeSeconds + 5.0;
		AttackShip.bHasFinishedEntry = true;
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
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
			DistanceAlongSpline = Math::Min(DistanceAlongSpline, Spline.GetLength());
			CooldownTime = Time::GameTimeSeconds + 1.0; // Deactivates behaviour
			bHasReachedFirstWaypoint = true;			
			return;
		}

		float SplineAlpha = DistanceAlongSpline/Spline.GetLength();
		FVector NewLocation = Spline.GetLocation(SplineAlpha);		
		
		Owner.SetActorLocation(NewLocation);
		if (!TargetComp.HasValidTarget())
		{
			float TurnDuration = Settings.TurnDuration;
			FVector Dir = Owner.ActorForwardVector.ConstrainToPlane(FVector::UpVector);
			AccRotation.AccelerateTo(Dir.Rotation(), TurnDuration, DeltaTime);
			AccRotation.SnapTo(Owner.ActorRotation);
			Owner.SetActorRotation(AccRotation.Value);
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (TargetComp.HasValidTarget() && !AttackShip.bHasPilotDied)
		{
			// Turn towards target
			FVector Direction = (TargetComp.Target.GetActorCenterLocation() - Owner.FocusLocation).GetSafeNormal();
			float Deg = Math::RadiansToDegrees(Math::Acos(Direction.DotProduct(FVector::UpVector)));
			if (Deg < 120) // Don't tip over when target falls over the edge
			{
				float TurnDuration = Settings.TurnDuration;
				AccRotation.AccelerateTo(Direction.Rotation(), TurnDuration, DeltaTime);
				Owner.SetActorRotation(AccRotation.Value);
			}
		}
	}

};