class UEnforcerHoverChaseBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UEnforcerHoveringSettings HoverSettings; 
	float VisibleDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HoverSettings =  UEnforcerHoveringSettings::GetSettings(Owner);
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

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		VisibleDuration = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(0.5); // Never twitch chase on/off
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector ChaseLocation = TargetComp.Target.ActorLocation;
		ChaseLocation.Z += HoverSettings.HoverChaseHeight;

		if (TargetComp.Target.ActorCenterLocation.IsWithinDist(Owner.ActorCenterLocation, HoverSettings.HoverChaseMinRange))
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
