class USanctuaryDodgerGrabDamageBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	USanctuaryDodgerGrabComponent GrabComp;
	USanctuaryDodgerSettings DodgerSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GrabComp = USanctuaryDodgerGrabComponent::Get(Owner);
		DodgerSettings = USanctuaryDodgerSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!GrabComp.bGrabbing)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!GrabComp.bGrabbing)
			return true;
		if(ActiveDuration > 1.0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		//GrabComp.GrabbedActor.TakeDamage(DodgerSettings.GrabDamage, Owner);
		USanctuaryDodgerEventHandler::Trigger_OnGrabDamage(Owner, FSanctuaryDodgerGrabDamageParams(GrabComp.GrabbedActor));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(DodgerSettings.GrabDamageCooldown);
	}
}