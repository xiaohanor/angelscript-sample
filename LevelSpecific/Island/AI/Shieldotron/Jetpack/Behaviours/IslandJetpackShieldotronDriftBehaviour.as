class UIslandJetpackShieldotronDriftBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UIslandJetpackShieldotronSettings HoverSettings; 
	UBasicAIResourceManager Resources;
	FVector DriftDirection;
	float DriftDuration;

	float CheckGeometryInterval = 0.1;
	float CheckGeometryTime;

	AHazeActor Target;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HoverSettings =  UIslandJetpackShieldotronSettings::GetSettings(Owner);
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
		Target = TargetComp.Target;
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
		FVector DriftLocation = Owner.ActorLocation + DriftDirection * 1500;

		// Check max height from target
		if (DriftLocation.Z > Target.ActorCenterLocation.Z + HoverSettings.HoverDriftMaxHeight)
		{
			DriftLocation.Z = Target.ActorCenterLocation.Z + HoverSettings.HoverDriftMaxHeight * 0.5;
		}

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
