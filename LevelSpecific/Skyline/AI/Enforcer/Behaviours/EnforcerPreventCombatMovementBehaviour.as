
class UEnforcerPreventCombatMovementBehaviour : UBasicBehaviour
{
	default Requirements.AddBlock(EBasicBehaviourRequirement::Movement);

	USkylineEnforcerSettings EnforcerSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		EnforcerSettings = USkylineEnforcerSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if(!TargetComp.HasValidTarget())
			return false;
		if(!EnforcerSettings.PreventCombatMovement)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if(!TargetComp.HasValidTarget())
			return true;
		if(!EnforcerSettings.PreventCombatMovement)
			return true;

		return false;
	}
}