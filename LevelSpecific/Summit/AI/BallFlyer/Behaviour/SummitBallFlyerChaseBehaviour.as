class USummitBallFlyerChaseBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	default CapabilityTags.Add(n"Chase");

	USummitBallFlyerSettings Settings;
	float StuckDuration;
	FVector StuckLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitBallFlyerSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!ShouldChase(TargetComp.Target, Settings.ChaseRange))
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
		if (ActiveDuration < Settings.ChaseMinDuration)
			return false;
		if (!ShouldChase(TargetComp.Target, Settings.ChaseRange * 1.2))
			return true;
		return false;
	}

	bool ShouldChase(AHazeActor Target, float Range) const
	{
		if (!TargetComp.IsValidTarget(Target))
			return false;

		FVector TargetLoc = Target.ActorCenterLocation;
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
		RelativeLoc.X = Settings.ChaseFlankingOffset.X;
		RelativeLoc.Y = Math::Sign(RelativeLoc.Y) * Settings.ChaseFlankingOffset.Y;
		RelativeLoc.Z = Settings.ChaseFlankingOffset.Z;
		FVector FlankingDest = TargetTransform.TransformPosition(RelativeLoc);
		DestinationComp.MoveTowards(FlankingDest, Settings.ChaseSpeed);
		DestinationComp.RotateTowards(TargetComp.Target);

		// Check if we've gotten stuck
		if (OwnLoc.IsWithinDist(StuckLocation, Settings.ChaseSpeed * 0.25))
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
