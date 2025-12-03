class USummitWeakenedBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UAcidTailBreakableComponent AcidTailBreakComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		AcidTailBreakComp = UAcidTailBreakableComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		if(!AcidTailBreakComp.IsWeakened())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;

		if(!AcidTailBreakComp.IsWeakened())
			return true;

		return false;
	}
}