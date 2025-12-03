
class UBasicBehaviour : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;
	default CapabilityTags.Add(BasicAITags::Behaviour);
	default DebugCategory = BasicAITags::Behaviour;

	FBasicBehaviourRequirements Requirements;
	FBasicBehaviourCooldown Cooldown;

	UBasicBehaviourComponent BehaviourComp;
    UBasicAITargetingComponent TargetComp;
	UBasicAIDestinationComponent DestinationComp;
	UBasicAIAnimationComponent AnimComp;
	UBasicAIPerceptionComponent PerceptionComp;
	UBasicAISettings BasicSettings;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BehaviourComp = UBasicBehaviourComponent::GetOrCreate(Owner);
    	TargetComp = UBasicAITargetingComponent::GetOrCreate(Owner);
		DestinationComp = UBasicAIDestinationComponent::GetOrCreate(Owner);
		AnimComp = UBasicAIAnimationComponent::GetOrCreate(Owner);
		PerceptionComp = UBasicAIPerceptionComponent::GetOrCreate(Owner);
		BasicSettings = UBasicAISettings::GetSettings(Owner);
		BehaviourComp.RegisterBehaviour();
		Requirements.Priority = 1000 - BehaviourComp.NumRegisteredBehaviours;		
	}

	UFUNCTION(BlueprintOverride, Meta = (RequireSuperCall))
	bool ShouldActivate() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		return true;		
	}

	UFUNCTION(BlueprintOverride, Meta = (RequireSuperCall))
	bool ShouldDeactivate() const
	{
		// Note that we deactivate whenever cooldown is set, not when !Cooldown.IsOver
		if (Cooldown.IsSet())
			return true; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return true;
		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Requirements.Claim(BehaviourComp, this);
		Cooldown.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Requirements.Release(BehaviourComp, this);
		AnimComp.ClearFeature(this);
	}

	void DeactivateBehaviour()
	{
		// This will deactivate behaviour next update
		if(!Cooldown.IsSet())
			Cooldown.Set(0.0);
	}
}

