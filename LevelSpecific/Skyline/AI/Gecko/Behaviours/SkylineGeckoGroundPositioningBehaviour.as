class USkylineGeckoGroundPositioningBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UBasicAIRuntimeSplineComponent SplineComp;
	USkylineGeckoComponent GeckoComp;
	UWallclimbingComponent WallclimbingComp;
	UTargetTrailComponent TrailComp;
	USkylineGeckoSettings Settings;
	bool bHasGroundDestination;
	FVector GroundDestination;
	FSplinePosition TargetSplinePos;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SplineComp = UBasicAIRuntimeSplineComponent::GetOrCreate(Owner);
		GeckoComp = USkylineGeckoComponent::GetOrCreate(Owner);
		WallclimbingComp = UWallclimbingComponent::GetOrCreate(Owner);
		Settings = USkylineGeckoSettings::GetSettings(Owner);

		UGentlemanComponent::GetOrCreate(Game::Zoe).SetMaxAllowedClaimants(GeckoToken::Grounded, Settings.PerchingMaxGeckos);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (TargetComp.Target != Game::Zoe)
			return false;
		UPlayerSplineLockComponent SplineLockComp = UPlayerSplineLockComponent::Get(TargetComp.Target);
		if ((SplineLockComp == nullptr) || (SplineLockComp.CurrentSpline == nullptr)) 
			return false;
		if (GeckoComp.ShouldPerch(TargetComp.GentlemanComponent))
			return false;		
		if (!TargetComp.GentlemanComponent.CanClaimToken(GeckoToken::Grounded, Owner))
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
		if (ActiveDuration > Settings.GroundPositioningMaxDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		TrailComp = UTargetTrailComponent::GetOrCreate(TargetComp.Target);
		GeckoComp.bAllowBladeHits.Apply(false, this);
		bHasGroundDestination = false;
		UPlayerSplineLockComponent SplineLockComp = UPlayerSplineLockComponent::Get(TargetComp.Target);
		TargetSplinePos = SplineLockComp.GetSplinePosition();

		// Release any perch when we go for ground
		if (GeckoComp.PerchPos.IsValid())
			GeckoComp.PerchPos.Release();

		TargetComp.GentlemanComponent.ClaimToken(GeckoToken::Grounded, Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GeckoComp.bAllowBladeHits.Clear(this);
		WallclimbingComp.DestinationUpVector.Clear(this);

		if (TargetComp.GentlemanComponent != nullptr) // If null, token will have already been released
			TargetComp.GentlemanComponent.ReleaseToken(GeckoToken::Grounded, Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		if (bHasGroundDestination && GroundDestination.IsWithinDist(TargetLoc, Settings.GroundPositioningMinDistance))
			bHasGroundDestination = false; // Need a better destination
		
		if (!bHasGroundDestination)
			FindGroundDestination();

		// If we have a nice place to come down from the wall, go there
		// Otherwise we approach target until within min distance and hope 
		// we can find a good ground position on the way.
		if (bHasGroundDestination)
		{
			DestinationComp.MoveTowards(GroundDestination, Settings.GroundPositioningMoveSpeed);
			FVector TargetUp = TargetComp.Target.ActorUpVector;
			WallclimbingComp.DestinationUpVector.Apply(TargetUp, this, EInstigatePriority::Normal);

			if (Owner.ActorLocation.IsWithinDist(GroundDestination, Settings.GroundPositioningDoneRange) && 
				(Owner.ActorUpVector.DotProduct(TargetUp) > 0.999))
			{
				// We're there!
				GeckoComp.ReachedGroundPosition = Owner.ActorLocation;
				Cooldown.Set(Settings.GroundPositioningCooldown);				
			}
		}
		else if (!Owner.ActorLocation.IsWithinDist(TargetLoc, Settings.GroundPositioningMinDistance))
		{
			DestinationComp.MoveTowards(TargetComp.Target.ActorCenterLocation, Settings.GroundPositioningMoveSpeed * 0.5);
		}
		else 
		{
			DestinationComp.RotateTowards(TargetComp.Target.ActorCenterLocation);
		}
	}

	void FindGroundDestination()
	{
		// Update where target is along spline. 
		float DeltaMove = TargetSplinePos.WorldForwardVector.DotProduct(TargetComp.Target.ActorLocation - TargetSplinePos.WorldLocation);
		TargetSplinePos.Move(DeltaMove);
		
		// Are we in front or behind target along spline?
		FVector FromTarget = Owner.ActorLocation - TargetComp.Target.ActorLocation;
		float Direction = (TargetSplinePos.WorldForwardVector.DotProduct(FromTarget) < 0.0) ? -1.0 : 1.0;
		float IdealDistAlongSpline = TargetSplinePos.CurrentSplineDistance + Direction * Settings.GroundPositioningIdealDistance;
		GroundDestination = TargetSplinePos.CurrentSpline.GetWorldLocationAtSplineDistance(IdealDistAlongSpline); 
		GroundDestination.Z = TargetComp.Target.ActorCenterLocation.Z;

		bHasGroundDestination = true;
		return;
	}
}