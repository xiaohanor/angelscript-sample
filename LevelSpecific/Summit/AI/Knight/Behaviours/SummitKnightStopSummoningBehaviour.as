class USummitKnightStopSummoningBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USummitKnightComponent KnightComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		KnightComp = USummitKnightComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Single tick only
		if (Super::ShouldDeactivate())
			return true;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		KnightComp.DeactivateSpawners();
	}
}

