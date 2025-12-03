class USummitMageModeBlockerBehaviour : UBasicBehaviour
{
	default Requirements.AddBlock(EBasicBehaviourRequirement::Movement);

	USummitMageModeComponent ModeComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ModeComp = USummitMageModeComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(ModeComp.Mode != ESummitMageMode::Ranged)
			return false;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ModeComp.Mode != ESummitMageMode::Ranged)
			return true;
		return true;
	}
}