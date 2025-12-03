class UIslandJetpackShieldotronMatchHeightBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	// TODO: Wish to modify current movement... this should be a capability.
	//default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UIslandJetpackShieldotronHoldWaypointComponent WaypointComp;

	UIslandJetpackShieldotronSettings JetpackSettings; 
	UBasicAIResourceManager Resources;
	float MaxDuration;

	float CheckGeometryInterval = 0.1;
	float CheckGeometryTime;

	AHazeActor Target;
	FVector Destination;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WaypointComp = UIslandJetpackShieldotronHoldWaypointComponent::GetOrCreate(Owner);
		JetpackSettings =  UIslandJetpackShieldotronSettings::GetSettings(Owner);
		Resources = Game::GetSingleton(UBasicAIResourceManager);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if(WaypointComp.Waypoint != nullptr)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > MaxDuration)
			return true;
		if (!TargetComp.IsValidTarget(Target))
			return false;
		if(WaypointComp.Waypoint != nullptr)
			return false;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		MaxDuration = Math::RandRange(3, 6);
		Target = TargetComp.Target;
		
		CheckGeometryTime = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(Math::RandRange(JetpackSettings.HoverDriftCooldownMin, JetpackSettings.HoverDriftCooldownMax));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!DestinationComp.HasDestination())
			return;
		
		// Prevent sliding along ground. Prefer being in the air.
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Target);
		if (MoveComp != nullptr && MoveComp.IsOnAnyGround())
			return;

		DestinationComp.Destination.Z = Target.ActorLocation.Z;
		Destination = DestinationComp.Destination;
		DestinationComp.MoveTowards(Destination, DestinationComp.Speed); // Keep current speed

		if (Destination.IsWithinDist(Owner.ActorCenterLocation, 200) )
			DeactivateBehaviour(); // Will set cooldown duration in OnDeactivated

		if ((Time::GameTimeSeconds > CheckGeometryTime) && Resources.CanUse(EAIResource::NavigationTrace))
		{
			Resources.Use(EAIResource::NavigationTrace);
			//if(Navigation::NavOctreeLineTrace(Owner.ActorLocation, Destination))
			//	DeactivateBehaviour();
			CheckGeometryTime = Time::GetGameTimeSeconds() + CheckGeometryInterval;
		}
	}
}
