class USummitKnightMobileHurtReactionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Movement);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Weapon);

	UBasicAIHealthComponent HealthComp;
	USummitKnightComponent KnightComp;
	USummitKnightStageComponent StageComp;
	USummitKnightSettings Settings;
	bool bHasReactedToHurt = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		KnightComp = USummitKnightComponent::Get(Owner);
		StageComp = USummitKnightStageComponent::Get(Owner);
		Settings = USummitKnightSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (bHasReactedToHurt)
			return false; // Each reaction only triggers once
		if (HealthComp.IsStunned())
			return false;
		if (!HasPassedHurtThreshold(StageComp.Phase))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.HurtReactionDuration) 
			return true; 
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bHasReactedToHurt = true;
		KnightComp.bCanBeStunned.Apply(false, this);
		AnimComp.RequestFeature(SummitKnightFeatureTags::HurtReaction, EBasicBehaviourPriority::High, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		KnightComp.bCanBeStunned.Clear(this);
	}

	bool HasPassedHurtThreshold(ESummitKnightPhase Phase) const
	{
		switch (Phase)
		{
			case ESummitKnightPhase::MobileStart:
				return (HealthComp.CurrentHealth < Settings.HealthThresholdStartToSwoop);	
			default:
				return false;	
		}
	}
}
