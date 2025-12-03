class UTundraGnatEngageBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UTundraGnatComponent GnatComp;
	UTundraGnatSettings Settings;
	float NoTreeDuration = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GnatComp = UTundraGnatComponent::Get(Owner); 
		Settings = UTundraGnatSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (GnatComp.TreeGuardianComp == nullptr)
			return false;
		if (Settings.bOnlyAnnoyTree && !GnatComp.TreeGuardianComp.bIsActive)
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
		if (!TargetComp.HasValidTarget())
			return true;
		if (Settings.bOnlyAnnoyTree && (NoTreeDuration > 0.5))
			return true;
		return false;
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if ((GnatComp.TreeGuardianComp != nullptr) && (GnatComp.TreeGuardianComp.bIsActive))
			NoTreeDuration = 0.0;
		else	
			NoTreeDuration += DeltaTime;

		DestinationComp.MoveTowardsIgnorePathfinding(TargetComp.Target.ActorLocation, Settings.EngageMoveSpeed);
	}
}
