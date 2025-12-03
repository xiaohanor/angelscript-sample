
class UPrisonGuardBotZapperTargetingBehaviour : UBasicBehaviour
{
	// Targeting is replicated separately
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	UPrisonGuardBotSettings Settings;
	UBasicAIHealthComponent HealthComp;
	float ReactionTime;
	AHazePlayerCharacter PendingTarget;
	float RetargetMioTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		Settings = UPrisonGuardBotSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if ((TargetComp.Target == Game::Zoe) && (Time::GameTimeSeconds > RetargetMioTime) && TargetComp.IsValidTarget(Game::Mio))
			return true; // We get bored chasing Zoe after a while
		if (WasAttackedByOtherPlayer())
			return true; // We can always strike back
		if (TargetComp.HasValidTarget())
			return false; // Unless the above is true we stay with current target as long as it's valid
		if ((TargetComp.Target != nullptr) && TargetComp.Target.IsAnyCapabilityActive(n"RemoteHackingLaunch"))
			return false; // Mio is not a valid target while remote hacking, but we should keep her as target even so	
		return true;
	}

	bool WasAttackedByOtherPlayer() const
	{
		if (Time::GetGameTimeSince(HealthComp.LastDamageTime) > 0.1)
			return false; 
		if (TargetComp.Target == HealthComp.LastAttacker)
			return false; 
		if (!TargetComp.IsValidTarget(HealthComp.LastAttacker))
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

		// If we were targeting Mio, we'll switch back after a while
		if (TargetComp.Target == Game::Mio)
			RetargetMioTime = Time::GameTimeSeconds + Settings.TargetingStayWithZoeDuration * Math::RandRange(0.8, 1.2);
		else
			RetargetMioTime = BIG_NUMBER;

		// Retarget a short while after losing previous target
		PendingTarget = (TargetComp.Target == Game::Mio) ? Game::Zoe : Game::Mio;
		ReactionTime = Settings.TargetingReactionTime * Math::RandRange(0.5, 1.5);
		if ((Time::GetGameTimeSince(HealthComp.LastDamageTime) < 0.2) && (PendingTarget == HealthComp.LastAttacker))
			ReactionTime *= 0.25;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if ((ActiveDuration > ReactionTime) && (TargetComp.IsValidTarget(PendingTarget)))
			TargetComp.SetTarget(PendingTarget);
	}
}