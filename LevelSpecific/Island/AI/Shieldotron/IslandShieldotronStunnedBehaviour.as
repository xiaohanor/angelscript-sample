class UIslandShieldotronStunnedBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	default CapabilityTags.Add(n"Stunned");

	UIslandForceFieldComponent ForceFieldComp;
	UIslandRedBlueImpactResponseComponent ResponseComp;
	UBasicAIHealthComponent HealthComp;
	UIslandShieldotronSettings Settings;
	
	bool bTriggerStunAnimation = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandShieldotronSettings::GetSettings(Owner);
		ForceFieldComp = UIslandForceFieldComponent::Get(Owner);
		ForceFieldComp.OnDepleting.AddUFunction(this, n"OnForceFieldDepleting");
		HealthComp = UBasicAIHealthComponent ::Get(Owner);
		ResponseComp = UIslandRedBlueImpactResponseComponent::GetOrCreate(Owner);
	}

	UFUNCTION()
	private void OnForceFieldDepleting(AHazeActor Instigator)
	{
		if (Owner.IsCapabilityTagBlocked(n"Stunned"))
			return;
		 bTriggerStunAnimation = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!bTriggerStunAnimation)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.StunnedDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(FeatureTagIslandSecurityMech::Stunned, EBasicBehaviourPriority::High, this, Settings.StunnedDuration);

		UIslandShieldotronEffectHandler::Trigger_OnStunned(Owner);
		UIslandShieldotronPlayerEffectHandler::Trigger_OnShieldotronStunned(Game::Mio, FIslandShieldotronPlayerEventData(Owner));
		UIslandShieldotronPlayerEffectHandler::Trigger_OnShieldotronStunned(Game::Zoe, FIslandShieldotronPlayerEventData(Owner));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AnimComp.ClearFeature(this);
		bTriggerStunAnimation = false;
	}
}
