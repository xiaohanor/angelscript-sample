class USummitCritterSwarmChaseBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	default CapabilityTags.Add(n"Chase");

	USummitCritterSwarmComponent SwarmComp;
	USummitCritterSwarmSettings SwarmSettings;
	float StuckDuration;
	FVector StuckLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SwarmComp = USummitCritterSwarmComponent::GetOrCreate(Owner);
		SwarmSettings = USummitCritterSwarmSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		float Range = (Time::GetGameTimeSince(SwarmComp.AggroTime) < 10.0) ? SwarmSettings.ChaseAggroRange : SwarmSettings.ChasePassiveRange;
		if (!ShouldChase(TargetComp.Target, Range))
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
		if (ActiveDuration < SwarmSettings.ChaseMinDuration)
			return false;
		if (!ShouldChase(TargetComp.Target, SwarmSettings.ChaseAggroRange))
			return true;
		return false;
	}

	bool ShouldChase(AHazeActor Target, float Range) const
	{
		if (!TargetComp.IsValidTarget(Target))
			return false;

		FVector TargetLoc = Target.ActorCenterLocation;
		if (!SwarmComp.IsAllowedLocation(TargetLoc))
			return false;

		FVector OwnLoc = Owner.ActorCenterLocation;
		if (!TargetLoc.IsWithinDist(OwnLoc, Range))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		StuckLocation = Owner.ActorLocation;
		StuckDuration = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorCenterLocation;
		
		// Chase to a flanking position
		FTransform TargetTransform = Cast<AHazePlayerCharacter>(TargetComp.Target).ViewTransform;
		FVector RelativeLoc = TargetTransform.InverseTransformPosition(OwnLoc);
		RelativeLoc.X = SwarmSettings.ChaseFlankingOffset.X;
		RelativeLoc.Y = Math::Sign(RelativeLoc.Y) * SwarmSettings.ChaseFlankingOffset.Y;
		RelativeLoc.Z = SwarmSettings.ChaseFlankingOffset.Z;
		FVector FlankingDest = TargetTransform.TransformPosition(RelativeLoc);
		FlankingDest = SwarmComp.ProjectToArea(FlankingDest);
		DestinationComp.MoveTowards(FlankingDest, SwarmSettings.ChaseSpeed);

		SwarmComp.AggroTime = Time::GameTimeSeconds;

		// Check if we've gotten stuck
		if (OwnLoc.IsWithinDist(StuckLocation, SwarmSettings.ChaseSpeed * 0.25))
		{
			StuckDuration += DeltaTime;
			if (StuckDuration > 3.0)
				Cooldown.Set(5.0); // Allow other behaviours to get us past obstacles
		}
		else
		{
			StuckDuration = 0.0;
			StuckLocation = OwnLoc;
		}

#if EDITOR
	 	// Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(TargetTransform.Location, FlankingDest, FLinearColor::Red, 10);		
			Debug::DrawDebugSphere(FlankingDest, 100, 4, FLinearColor::Red, 10);
			//Debug::DrawDebugSphere(TargetComp.Target.ActorCenterLocation + FVector(0,0,400), 100, 4, FLinearColor::Red, 10);
		}
#endif
	}
}
