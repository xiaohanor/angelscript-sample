class UIslandShieldotronLandBehaviour : UBasicBehaviour
{	
	default Requirements.AddBlock(EBasicBehaviourRequirement::Movement);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Weapon);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Focus);

	UIslandShieldotronJumpComponent JumpComp;
	UIslandForceFieldComponent ForceFieldComp;
	UIslandShieldotronSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		JumpComp = UIslandShieldotronJumpComponent::Get(Owner);
		ForceFieldComp = UIslandForceFieldComponent::GetOrCreate(Owner);
		Settings = UIslandShieldotronSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!JumpComp.bIsLanding)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.LandingDelay)
			return true;
		if (!JumpComp.bIsLanding)
			return true;
		if (ForceFieldComp.IsDepleted())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		
		//Owner.BlockCapabilities(CapabilityTags::Movement, this);
		UBasicAIMovementSettings::SetGroundFriction(Owner, 20.0, this);
		
		if (ForceFieldComp.IsDepleted())
			return;
		if (!JumpComp.bSkipLandingAnimation)
			AnimComp.RequestFeature(FeatureTagIslandSecurityMech::Land, EBasicBehaviourPriority::High, Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AnimComp.ClearFeature(Owner);
		JumpComp.bIsLanding = false;
		JumpComp.bIsJumping = false;
		JumpComp.bSkipLandingAnimation = false;
		//Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		UBasicAIMovementSettings::ClearGroundFriction(Owner, this);
	}

}
