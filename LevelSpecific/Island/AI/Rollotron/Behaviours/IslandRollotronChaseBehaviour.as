// Move towards enemy
class UIslandRollotronChaseBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UIslandRollotronSettings Settings;

	float NextCheckTimer = 0.0;
	bool bHasViewOfTarget = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandRollotronSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!TargetComp.Target.ActorCenterLocation.IsWithinDist(Owner.ActorCenterLocation, Settings.ChaseMaxRange))
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
		if (TargetComp.Target.ActorCenterLocation.IsWithinDist(Owner.ActorCenterLocation, Settings.ChaseMinRange))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		NextCheckTimer = 1.0;
		bHasViewOfTarget = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Keep moving towards target!
		NextCheckTimer -= DeltaTime;
		if (NextCheckTimer < 0.0)
		{
			NextCheckTimer = 1.0;
			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
			Trace.UseLine();
			FHitResult Hit = Trace.QueryTraceSingle(Owner.ActorCenterLocation, TargetComp.Target.ActorCenterLocation);
			bHasViewOfTarget = !Hit.bBlockingHit;
		}

		if (bHasViewOfTarget)
			DestinationComp.MoveTowardsIgnorePathfinding(TargetComp.Target.ActorLocation, Settings.ChaseMoveSpeed);
		else
			DestinationComp.MoveTowards(TargetComp.Target.ActorLocation, Settings.ChaseMoveSpeed);
	}
}