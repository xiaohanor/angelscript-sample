class USummitKnightReformSpearBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	
	USummitKnightSpearComponent SpearComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SpearComp = USummitKnightSpearComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!SpearComp.bShattered)
			return false;
		if(Time::GetGameTimeSince(SpearComp.bShatteredTime) < 3)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > 3)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		SpearComp.Reform();
	}
}