class USummitKnightReformShieldBehaviour : UBasicBehaviour
{		
	USummitKnightShieldComponent ShieldComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ShieldComp = USummitKnightShieldComponent::GetOrCreate(Owner);
		ShieldComp.AddComponentVisualsBlocker(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(ShieldComp.bReformed)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > 0.5)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		ShieldComp.bReformed = true;
		ShieldComp.RemoveComponentVisualsBlocker(Owner);
	}
}