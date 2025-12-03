class USummitKnightReformSwordBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	
	USummitKnightSwordComponent SwordComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SwordComp = USummitKnightSwordComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!SwordComp.bShattered)
			return false;
		if(Time::GetGameTimeSince(SwordComp.bShatteredTime) < 3)
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
		SwordComp.Reform();
	}
}