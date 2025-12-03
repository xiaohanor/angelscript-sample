
class UIslandShieldotronDamageReactionBehaviour : UBasicBehaviour
{
	UIslandRedBlueImpactResponseComponent ResponseComp;	
	UBasicAIHealthComponent HealthComp;
	UIslandForceFieldComponent ForceField;
	UIslandShieldotronSettings ShieldotronSettings;
		
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ShieldotronSettings = UIslandShieldotronSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		ResponseComp = UIslandRedBlueImpactResponseComponent::GetOrCreate(Owner);
		ForceField = UIslandForceFieldComponent::GetOrCreate(Owner);
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (Time::GetGameTimeSince(HealthComp.LastDamageTime) > 0.1)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > ShieldotronSettings.HurtReactionDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();		
		AnimComp.RequestFeature(FeatureTagIslandSecurityMech::SmallHitReaction, EBasicBehaviourPriority::Medium, this, ShieldotronSettings.HurtReactionDuration);		
	}
}

