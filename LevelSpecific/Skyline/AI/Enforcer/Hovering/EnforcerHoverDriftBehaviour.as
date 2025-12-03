class UEnforcerHoverDriftBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UEnforcerHoveringSettings HoverSettings; 
	UBasicAIResourceManager Resources;
	FVector DriftDirection;
	float DriftDuration;

	float CheckGeometryInterval = 0.1;
	float CheckGeometryTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HoverSettings =  UEnforcerHoveringSettings::GetSettings(Owner);
		Resources = Game::GetSingleton(UBasicAIResourceManager);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
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
		if (ActiveDuration > DriftDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		DriftDuration = Math::RandRange(3, 6);
		FVector DirectionLocation = (Owner.ActorLocation + Math::GetRandomPointOnSphere() * 1000);
		DriftDirection = (DirectionLocation - Owner.ActorLocation).GetSafeNormal();
		CheckGeometryTime = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(Math::RandRange(HoverSettings.HoverDriftCooldownMin, HoverSettings.HoverDriftCooldownMax));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector DriftLocation = Owner.ActorLocation + DriftDirection * 1000;
		DestinationComp.MoveTowards(DriftLocation, HoverSettings.HoverDriftMoveSpeed);

		if ((Time::GameTimeSeconds > CheckGeometryTime) && Resources.CanUse(EAIResource::NavigationTrace))
		{
			Resources.Use(EAIResource::NavigationTrace);
			if(Navigation::NavOctreeLineTrace(Owner.ActorLocation, DriftLocation))
				DeactivateBehaviour();
			CheckGeometryTime = Time::GetGameTimeSeconds() + CheckGeometryInterval;
		}
	}
}
