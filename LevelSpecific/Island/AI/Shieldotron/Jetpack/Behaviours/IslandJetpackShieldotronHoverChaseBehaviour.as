class UIslandJetpackShieldotronHoverChaseBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UIslandJetpackShieldotronHoldWaypointComponent WaypointComp;

	UIslandJetpackShieldotronSettings HoverSettings; 
	float VisibleDuration;

	AHazeActor Target;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WaypointComp = UIslandJetpackShieldotronHoldWaypointComponent::GetOrCreate(Owner);
		HoverSettings =  UIslandJetpackShieldotronSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (TargetComp.Target.ActorCenterLocation.IsWithinDist(Owner.ActorCenterLocation, HoverSettings.HoverChaseMinRange))
			return false;
		if (TargetComp.HasVisibleTarget())
			return false; // Chase when target is not visible
		if (WaypointComp.Waypoint != nullptr)
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
		if (VisibleDuration > 2.0)
			return true;
		if (WaypointComp.Waypoint != nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		VisibleDuration = 0.0;
		Target = TargetComp.Target;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(0.5);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// TODO: Adjust chase location for when player is airborne
		float HeightDiff = (Owner.ActorLocation.Z - Target.ActorLocation.Z);
		if (Owner.ActorLocation.Dist2D(Target.ActorLocation) < HoverSettings.HoverChaseMinRange && Math::IsWithin(HeightDiff, 100, 600))
			Cooldown.Set(0.1);

		FVector ChaseLocation = Target.ActorLocation;

		ChaseLocation.Z = Target.ActorLocation.Z + HoverSettings.HoverChaseHeight;

		if (Target.ActorCenterLocation.IsWithinDist(Owner.ActorCenterLocation, HoverSettings.HoverChaseMinRange))
		{
			Cooldown.Set(0.5);
			return;
		}

		if (TargetComp.HasVisibleTarget())
			VisibleDuration += DeltaTime;
		else
			VisibleDuration = 0.0;

		// Keep moving towards target!
		DestinationComp.MoveTowards(ChaseLocation, HoverSettings.HoverChaseMoveSpeed);
	}
}
