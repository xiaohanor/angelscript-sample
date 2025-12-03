class USkylineEnforcerForceFieldBreakBehaviour : UBasicBehaviour
{
	USkylineEnforcerForceFieldComponent ForceFieldComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ForceFieldComp = USkylineEnforcerForceFieldComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!ForceFieldComp.bBroken)
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
		UEnforcerEffectHandler::Trigger_OnForceFieldBreak(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		ForceFieldComp.ForceField.bEnabled = false;
		ForceFieldComp.bBroken = false;
	}
}