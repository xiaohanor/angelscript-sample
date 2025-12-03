
class UPrisonGuardTargetingBehaviour : UBasicBehaviour
{
	// Targeting is replicated separately
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	UPrisonGuardSettings Settings;
	UBasicAIHealthComponent HealthComp;
	float ReactionTime;
	AHazePlayerCharacter PendingTarget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		
		Settings = UPrisonGuardSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (TargetComp.HasValidTarget())
			return false; 
		return true;
	}

	bool WasAttackedByOtherPlayer() const
	{
		if (Time::GetGameTimeSince(HealthComp.LastDamageTime) > 0.1)
			return false; 
		if (TargetComp.Target == HealthComp.LastAttacker)
			return false; 
		if (!IsValidTarget(HealthComp.LastAttacker))
			return false;
		if (!HealthComp.LastAttacker.IsA(AHazePlayerCharacter))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > ReactionTime)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		// Retarget a short while after losing previous target
		ReactionTime = Settings.TargetingReactionTime * Math::RandRange(0.5, 1.5);
		PendingTarget = (TargetComp.Target == Game::Mio) ? Game::Zoe : Game::Mio;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if ((ActiveDuration > ReactionTime) && IsValidTarget(PendingTarget))
			TargetComp.SetTarget(PendingTarget);
	}

	bool IsValidTarget(AHazeActor Target) const
	{
		if (!TargetComp.IsValidTarget(Target))
			return false;
		
		// Don't target remote hacking player
		URemoteHackingPlayerComponent HackingComp = URemoteHackingPlayerComponent::Get(Target);
		if ((HackingComp != nullptr) && HackingComp.bHackActive)
			return false;

		return true;
	}
}