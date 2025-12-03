class USanctuaryDodgerGrabReleaseBehaviour : UBasicBehaviour
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

		auto DarkPortalResponseComp = UDarkPortalResponseComponent::Get(Owner);
		DarkPortalResponseComp.OnAttached.AddUFunction(this, n"OnDarkPortalAttached");
	}

	UFUNCTION()
	private void OnDarkPortalAttached(ADarkPortalActor Portal, USceneComponent AttachComponent)
	{
		if(IsActive())
			DeactivateBehaviour();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!GrabComp.bGrabbing)
			return false;
		if(Time::GetGameTimeSince(GrabComp.GrabTime) < DodgerSettings.GrabDuration)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > DodgerSettings.ReleaseDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GrabComp.Release();
	}
}