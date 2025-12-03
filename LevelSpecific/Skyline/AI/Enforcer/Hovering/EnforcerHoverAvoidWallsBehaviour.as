class UEnforcerHoverAvoidWallsBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UEnforcerHoveringSettings HoverSettings; 
	UBasicAIResourceManager Resources;

	FVector AvoidanceDir = FVector::ZeroVector;
	float AvoidanceEndTime;

	float CheckNavigationInterval = 0.1;
	float CheckNavigationTime;

	int iCheckNavigationDir = 0;
	TArray<FVector> NavigationCheckDir;
	default NavigationCheckDir.Add(-FVector::UpVector);
	default NavigationCheckDir.Add(FVector::ForwardVector);
	default NavigationCheckDir.Add(-FVector::ForwardVector);
	default NavigationCheckDir.Add(FVector::RightVector);
	default NavigationCheckDir.Add(-FVector::RightVector);
	default NavigationCheckDir.Add(FVector::UpVector);

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HoverSettings =  UEnforcerHoveringSettings::GetSettings(Owner);
		Resources = Game::GetSingleton(UBasicAIResourceManager);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsBlocked())
			return;
		if (!Cooldown.IsOver())
			return; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return;
		if (Time::GameTimeSeconds < CheckNavigationTime)
			return;
		if (!Resources.CanUse(EAIResource::NavigationTrace))
			return;

		Resources.Use(EAIResource::NavigationTrace);
		FVector CheckDir = NavigationCheckDir[iCheckNavigationDir]; 
		if (Navigation::NavOctreeLineTrace(Owner.ActorLocation, Owner.ActorLocation + CheckDir * HoverSettings.HoverAvoidWallsDistance))
		{
			// Found wall
			if (AvoidanceDir.IsZero())
				AvoidanceDir = -CheckDir;
			else 
				AvoidanceDir = (AvoidanceDir - CheckDir * 2.0) / 3.0;	
			AvoidanceEndTime = Time::GameTimeSeconds + HoverSettings.HoverAvoidWallsDuration;
		}
		else if (Time::GameTimeSeconds > AvoidanceEndTime)
		{
			AvoidanceDir = FVector::ZeroVector;	
		}

		iCheckNavigationDir = (iCheckNavigationDir + 1) % NavigationCheckDir.Num();
		CheckNavigationTime = Time::GameTimeSeconds + CheckNavigationInterval;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false; 
		if (AvoidanceDir.IsZero())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (Time::GameTimeSeconds > AvoidanceEndTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AvoidanceEndTime = Time::GameTimeSeconds + HoverSettings.HoverAvoidWallsDuration;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AvoidanceDir = FVector::ZeroVector;
		Cooldown.Set(0.5);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector AvoidLocation = Owner.ActorLocation + AvoidanceDir * 1000;
		DestinationComp.MoveTowardsIgnorePathfinding(AvoidLocation, HoverSettings.HoverAvoidWallsMoveSpeed);
	}
}
