class UPrisonGuardBotHitReactionBehaviour : UBasicBehaviour
{
	default CapabilityTags.Add(n"HitReaction");
	default BlockExclusionTags.Add(n"HitReaction");

	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	UBasicAIHealthComponent HealthComp;
	UPrisonGuardBotSettings Settings;

	float RecoverTime;

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
		if (Time::GetGameTimeSince(HealthComp.LastDamageTime) > Settings.HitreactionDuration - KINDA_SMALL_NUMBER)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > RecoverTime)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		RecoverTime = Settings.HitreactionDuration;
		AnimComp.RequestFeature(PrisonZapperAnimTags::HitReaction, EBasicBehaviourPriority::High, this);

		UPrisonGuardBotEffectHandler::Trigger_OnHitReactionStart(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		UPrisonGuardBotEffectHandler::Trigger_OnHitReactionStop(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float MinRecoverTime = ActiveDuration + HealthComp.LastDamageTime - Time::GameTimeSeconds + Settings.HitreactionDuration;
		if (RecoverTime < MinRecoverTime)
			RecoverTime = MinRecoverTime;
	}
}

