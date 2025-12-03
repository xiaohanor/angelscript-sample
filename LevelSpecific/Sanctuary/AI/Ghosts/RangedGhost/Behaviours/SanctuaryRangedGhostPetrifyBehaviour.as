class USanctuaryRangedGhostPetrifyBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UBasicAIHealthComponent HealthComp;

	bool bPetrified;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		auto DarkPortalComp = UDarkPortalResponseComponent::Get(Owner);
		DarkPortalComp.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		HealthComp = UBasicAIHealthComponent::Get(Owner);

		auto LightBirdComp = ULightBirdResponseComponent::Get(Owner);
		LightBirdComp.OnIlluminated.AddUFunction(this, n"OnIlluminated");
		LightBirdComp.OnUnilluminated.AddUFunction(this, n"OnUnilluminated");
	}

	
	UFUNCTION()
	private void OnUnilluminated()
	{
		bPetrified = false;
	}

	UFUNCTION()
	private void OnIlluminated()
	{
		bPetrified = true;
	}

	UFUNCTION()
	private void OnGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponenet)
	{
		if(bPetrified)
			HealthComp.Die();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!bPetrified)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!bPetrified)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Owner.SetActorTimeDilation(0.0, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.ClearActorTimeDilation(this);
	}
}