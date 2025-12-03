class USummitCritterSwarmGuardSplineBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USummitCritterSwarmComponent SwarmComp;
	USummitCritterSwarmSettings SwarmSettings;
	USummitTeenDragonRollingLiftComponent LiftComp;
	FSplinePosition SplinePos;
	FSplinePosition TargetSplinePos;
	AHazePlayerCharacter BallPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SwarmComp = USummitCritterSwarmComponent::GetOrCreate(Owner);
		SwarmSettings = USummitCritterSwarmSettings::GetSettings(Owner);
		BallPlayer = Game::Zoe;
		LiftComp = USummitTeenDragonRollingLiftComponent::GetOrCreate(BallPlayer);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		
		// Only used when Zoe is on spline
		if (LiftComp.CurrentSpline == nullptr)
			return false;
		if (!Owner.ActorLocation.IsWithinDist(BallPlayer.ActorLocation, SwarmSettings.GuardSplineRange))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		if ((LiftComp.CurrentSpline != nullptr) && (LiftComp.CurrentSpline != SplinePos.CurrentSpline))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		SplinePos = LiftComp.CurrentSpline.GetClosestSplinePositionToWorldLocation(Owner.ActorLocation);
		TargetSplinePos = LiftComp.CurrentSpline.GetClosestSplinePositionToWorldLocation(BallPlayer.ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorCenterLocation;
		
		// Update target spline position (note that if taret moves off spline, we use last spline position)
		if (LiftComp.CurrentSpline != nullptr)
		{
			float Delta = SplinePos.WorldForwardVector.DotProduct(BallPlayer.ActorLocation - TargetSplinePos.WorldLocation);
			TargetSplinePos.Move(Delta);
		}

		// Move to spline, then along it towards target
		FVector DestOffset = FVector(0.0, 0.0, SwarmComp.BoundsRadius);
		if (OwnLoc.IsWithinDist(SplinePos.WorldLocation + DestOffset, SwarmSettings.GuardSplineAtSplineDistance))
		{
			float Direction = Math::Sign(TargetSplinePos.CurrentSplineDistance - SplinePos.CurrentSplineDistance);
			SplinePos.Move(Direction * SwarmSettings.GuardSplineMoveSpeed * DeltaTime);
		}
		DestinationComp.MoveTowards(SplinePos.WorldLocation + DestOffset, SwarmSettings.GuardSplineMoveSpeed);

		if (IsNearTarget(SwarmSettings.GuardSplineMinRange))
			Cooldown.Set(SwarmSettings.GuardSplineMinRangeCooldown);

#if EDITOR
	 	// Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(SplinePos.WorldLocation, SplinePos.WorldLocation + FVector(0,0,1000), FLinearColor::LucBlue, 10);
			Debug::DrawDebugSphere(SplinePos.WorldLocation, 100, 4, FLinearColor::LucBlue, 10);
			Debug::DrawDebugLine(TargetSplinePos.WorldLocation, TargetSplinePos.WorldLocation + FVector(0,0,1000), FLinearColor::Blue, 10);
		}
#endif
	}

	bool IsNearTarget(float Range)
	{
		if (Owner.ActorLocation.IsWithinDist(BallPlayer.ActorLocation, Range))
			return true;
		float SplineDelta = TargetSplinePos.CurrentSplineDistance - SplinePos.CurrentSplineDistance;
		if (Math::IsNearlyZero(SplineDelta, Math::Max(Range - SwarmSettings.GuardSplineAtSplineDistance, 1000.0)))
			return true;
		return false;		
	}
}
