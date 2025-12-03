class UPrisonStealthGuardPatrolWaitCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonStealthTags::StealthGuard);
	default CapabilityTags.Add(PrisonStealthTags::BlockedWhileStunned);
	default CapabilityTags.Add(PrisonStealthTags::BlockedWhileSearching);

	APrisonStealthGuard StealthGuard;
	UPrisonStealthGuardPatrolComponent PatrolComp;
	float DefaultYaw;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StealthGuard = Cast<APrisonStealthGuard>(Owner);
		PatrolComp = UPrisonStealthGuardPatrolComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPrisonStealthGuardPatrolWaitActivatedParams& Params) const
	{
		if(!PatrolComp.HasAnySections())
			return false;

		if(!PatrolComp.GetCurrentSectionIsStandStill())
			return false;

		FPrisonStealthGuardSection NextSection = PatrolComp.PeekNextSection();
		Params.DefaultYaw = NextSection.GetSpline().GetClosestSplineWorldRotationToWorldLocation(StealthGuard.ActorLocation).Rotator().Yaw;
		if(PatrolComp.CurrentSectionIndex == PatrolComp.Sections.Num() - 1)
			Params.DefaultYaw += 180.0;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!PatrolComp.HasAnySections())
			return true;

		if(!PatrolComp.GetCurrentSectionIsStandStill())
			return true;

		// Wait for the duration to elapse
		if(ActiveDuration > PatrolComp.GetCurrentSection().Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPrisonStealthGuardPatrolWaitActivatedParams Params)
	{
		DefaultYaw = Params.DefaultYaw;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PatrolComp.GoToNextSection();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
			TickControl(DeltaTime);
		else
			TickRemote(DeltaTime);
	}

	void TickControl(float DeltaTime)
	{
		const FPrisonStealthGuardSection Section = PatrolComp.GetCurrentSection();

		float WaitAlpha = ActiveDuration / Section.Duration;
		WaitAlpha = Math::Saturate(WaitAlpha);

		float Yaw = DefaultYaw;
		if(WaitAlpha > Section.StartTurningDuringStandStillAlpha)
			Yaw += 180.0;

		StealthGuard.TargetYaw = Yaw;
		
		if(Section.bSwivelBackAndForth)
			StealthGuard.TargetYaw += Math::Sin(ActiveDuration * PatrolComp.SwivelFrequency) * Section.SwivelAmount;

#if EDITOR
		TEMPORAL_LOG(this)
			.Value("Target Yaw", StealthGuard.TargetYaw)
			.Value("Wait Alpha", WaitAlpha)
			.Value("Start Turning During Stand Still Alpha", Section.StartTurningDuringStandStillAlpha)
		;
#endif
	}

	void TickRemote(float DeltaTime)
	{

	}
}

struct FPrisonStealthGuardPatrolWaitActivatedParams
{
	float DefaultYaw;
}