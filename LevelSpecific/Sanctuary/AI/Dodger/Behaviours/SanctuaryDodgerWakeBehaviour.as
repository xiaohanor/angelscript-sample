class USanctuaryDodgerWakeBehaviour : UBasicBehaviour
{
	default CapabilityTags.Add(SanctuaryDodgerTags::SanctuaryDodgerDarkPortalBlock);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	USanctuaryDodgerSleepComponent SleepComp;
	USanctuaryDodgerSettings DodgerSettings;
	AAISanctuaryDodger Dodger;

	bool bHasWoken = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Dodger = Cast<AAISanctuaryDodger>(Owner);
		DodgerSettings = USanctuaryDodgerSettings::GetSettings(Owner);
		SleepComp = USanctuaryDodgerSleepComponent::Get(Owner);
		auto RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
	}

	UFUNCTION()
	private void OnReset()
	{
		bHasWoken = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(bHasWoken)
			return false;
		if(!SleepComp.bWaking && !TargetComp.HasValidTarget())
			return false;
		if(!SleepComp.bSleeping)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!SleepComp.bWaking)
			return true;
		if(ActiveDuration > DodgerSettings.SleepWakeDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(FeatureTagDodger::Sleeping, SubTagDodgerSleeping::WakeUp, EBasicBehaviourPriority::Medium, this, DodgerSettings.SleepWakeDuration);
		bHasWoken = true;
		SleepComp.Wake();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AnimComp.RequestFeature(FeatureTagDodger::Default, EBasicBehaviourPriority::Medium, this);
		SleepComp.FinishWake();
	}
}