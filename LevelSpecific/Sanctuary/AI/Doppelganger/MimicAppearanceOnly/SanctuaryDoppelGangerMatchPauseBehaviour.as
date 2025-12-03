class USanctuaryDoppelGangerMatchPauseBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USanctuaryDoppelgangerSettings DoppelSettings;
	USanctuaryDoppelgangerComponent DoppelComp;

	float PausedDuration = 0.0;
	float NotPausedDuration = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		DoppelSettings = USanctuaryDoppelgangerSettings::GetSettings(Owner);
		DoppelComp = USanctuaryDoppelgangerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if ((IsBlocked()) || (DoppelComp.MimicTarget == nullptr))
		{
			PausedDuration = 0.0;
			NotPausedDuration = 0.0;
			return;
		}

		if (DoppelComp.MimicTarget.ActorVelocity.Size() > DoppelSettings.MatchPauseVelocityThreshold)
		{
			PausedDuration = 0.0;
			NotPausedDuration += DeltaTime;
		}
		else
		{
			PausedDuration += DeltaTime;
			NotPausedDuration = 0.0;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (DoppelComp.MimicState == EDoppelgangerMimicState::FullMimic)
			return false;
		if (DoppelComp.MimicState == EDoppelgangerMimicState::Reveal)
			return false;
		if (PausedDuration < DoppelSettings.MatchPauseStartDelay)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (DoppelComp.MimicState == EDoppelgangerMimicState::FullMimic)
			return true;
		if (DoppelComp.MimicState == EDoppelgangerMimicState::Reveal)
			return true;
		if (NotPausedDuration > DoppelSettings.MatchPauseEndDelay)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		// Just stop in place and look like you are a real person
		AnimComp.RequestFeature(LocomotionFeatureAISanctuaryTags::DoppelgangerMimicMovement, EBasicBehaviourPriority::Low, this);
		AnimComp.RequestOverrideFeature(LocomotionFeatureAISanctuaryTags::DoppelgangerCreepyPause, this);
	}
}


