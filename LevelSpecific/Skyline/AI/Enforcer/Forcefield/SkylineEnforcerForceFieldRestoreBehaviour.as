class USkylineEnforcerForceFieldRestoreBehaviour : UBasicBehaviour
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
		if(ForceFieldComp.ForceField.bEnabled)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < 3)
			return;
		
		ForceFieldComp.Restore();
		UEnforcerEffectHandler::Trigger_OnForceFieldRestore(Owner);
		DeactivateBehaviour();
	}
}