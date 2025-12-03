class USummitCritterSwarmEvadeBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USummitCritterSwarmComponent SwarmComp;
	USummitCritterSwarmSettings SwarmSettings;

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
		if (!ShouldEvade(TargetComp.Target))
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
		if (ActiveDuration < SwarmSettings.EvadeMinDuration)
			return false; // Always evade for a while
		if (!ShouldEvade(TargetComp.Target))
			return true;
		return false;
	}

	bool ShouldEvade(AHazeActor Target) const
	{
		if (!TargetComp.IsValidTarget(Target))
			return false;

		FVector OwnLoc = Owner.ActorCenterLocation;
		FVector TargetLoc = Target.ActorCenterLocation;
		if (!TargetLoc.IsWithinDist(OwnLoc, SwarmSettings.EvadeRange))
			return false;

		float MinCosAngle = Math::Cos(Math::DegreesToRadians(SwarmSettings.EvadeMinAngle));
		if (Target.ActorForwardVector.DotProduct((OwnLoc - TargetLoc).GetSafeNormal()) < MinCosAngle)
			return false;	

		return true;
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorCenterLocation;
		FVector TargetLoc = TargetComp.Target.ActorCenterLocation;
		FVector TargetDir = TargetComp.Target.ActorForwardVector; // Velocity might be better
		FVector SideAwayDir = (OwnLoc - TargetLoc.PointPlaneProject(OwnLoc, TargetDir)).GetSafeNormal();	

		// Evade directly away and more to the side the closer the target gets.
		FVector EvadeDir = (SideAwayDir * SwarmSettings.EvadeRange * 0.5 + (OwnLoc - TargetLoc) + Owner.ActorVelocity * 1.0).GetSafeNormal();
		FVector EvadeDest = Owner.ActorLocation + EvadeDir * 1000.0;
		EvadeDest = SwarmComp.ProjectToArea(EvadeDest);
		DestinationComp.MoveTowards(EvadeDest, SwarmSettings.EvadeSpeed);

		SwarmComp.AggroTime = Time::GameTimeSeconds;

#if EDITOR
	 	// Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(TargetLoc + FVector(0,0,400), 100, 4, FLinearColor::Yellow, 10);
			Debug::DrawDebugLine(OwnLoc, EvadeDest, FLinearColor::Yellow, 100);
		}
#endif
	}
}
