class UCoastJetskiEngageBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UCoastJetskiSettings Settings;
	UCoastJetskiComponent JetskiComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UCoastJetskiSettings::GetSettings(Owner);
		JetskiComp = UCoastJetskiComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!JetskiComp.RailPosition.IsValid())
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
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		JetskiComp.TrainFollowSpeedAdjustment.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector RailDir = JetskiComp.RailPosition.WorldForwardVector;
		FVector Destination = JetskiComp.MoveWithinClosestSpline(TargetComp.Target.ActorLocation + RailDir * Settings.EngageDistanceAheadOfPlayer, Settings.EngageWithinSplineBuffer);	
		float SpeedFactor = Math::Min(1.0, 1.2 + RailDir.DotProduct((Destination - Owner.ActorLocation).GetSafeNormal2D()));
		DestinationComp.MoveTowardsIgnorePathfinding(Destination, Settings.EngageMoveSpeed * SpeedFactor);

		// If we're behind target, gain extra speed along rail
		float BehindDist = RailDir.DotProduct(TargetComp.Target.ActorLocation - Owner.ActorLocation); 
		if (BehindDist > 0.0)
			JetskiComp.TrainFollowSpeedAdjustment.Apply(Math::Min(Settings.EngageBehindExtraSpeed, BehindDist * 0.5), this, EInstigatePriority::Normal);
	}
}
