class UIslandJetpackShieldotronHoldWaypointBehaviour : UBasicBehaviour
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UBasicAIDestinationComponent DestComp;
	UIslandJetpackShieldotronHoldWaypointComponent WaypointComp;
	
	UIslandJetpackShieldotronSettings Settings;
		
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();		
		DestComp = UBasicAIDestinationComponent::Get(Owner);
		WaypointComp = UIslandJetpackShieldotronHoldWaypointComponent::GetOrCreate(Owner);
		Settings = UIslandJetpackShieldotronSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!IslandJetpackShieldotron::HasTacticalWaypointsInLevel())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (WaypointComp.Waypoint == nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{	
		Super::OnActivated();

		// Add ignore actors to waypoint's visibility check
		TArray<AHazeActor> IgnoreActors;
		IgnoreActors.Add(Owner);
		
		// Try find a waypoint
		AIslandJetpackShieldotronTacticalWaypoint OutWaypoint;
		IslandJetpackShieldotron::GetBestTacticalWaypoint(Owner, Cast<AHazeActor>(TargetComp.Target), IgnoreActors, OutWaypoint);
		if (WaypointComp.Waypoint != nullptr && WaypointComp.Waypoint != OutWaypoint)
			WaypointComp.Waypoint.Release();
		if (OutWaypoint != nullptr)
		{
			OutWaypoint.Hold(Owner);
			WaypointComp.Waypoint = OutWaypoint;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (TargetComp.HasValidTarget() && Owner.ActorLocation.DistSquared(TargetComp.Target.ActorLocation) < Settings.HoldWaypointMaxRange * Settings.HoldWaypointMaxRange)
			Cooldown.Set(Math::RandRange(4.0, 5.0));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(WaypointComp.Waypoint == nullptr)
			return;
		
		//Debug::DrawDebugLine(Owner.ActorLocation, WaypointComp.Waypoint.ActorLocation);
		//Debug::DrawDebugSphere(WaypointComp.Waypoint.ActorLocation, WaypointComp.Waypoint.Radius, 12, FLinearColor::Green);

		// if is at waypoint, set cooldown
		if (WaypointComp.Waypoint.IsAt(Owner, WaypointComp.Waypoint.Radius * 0.2))
		{
			DeactivateBehaviour();
			return;
		}
		float MoveSpeed = Settings.HoldWaypointMoveSpeed * Math::Clamp(Owner.ActorLocation.DistSquared(WaypointComp.Waypoint.ActorLocation) / (1000 * 1000), 0, 1);
		DestinationComp.MoveTowards(WaypointComp.Waypoint.ActorLocation, MoveSpeed);
	}
};