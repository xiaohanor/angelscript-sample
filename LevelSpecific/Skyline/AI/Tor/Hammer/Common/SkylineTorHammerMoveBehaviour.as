
class USkylineTorHammerMoveBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	UBasicAIHealthComponent HealthComp;
	USkylineTorHammerComponent HammerComp;
	USkylineTorSettings Settings;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
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
	void OnActivated()
	{
		Super::OnActivated();
		HammerComp.bGroundOffset.Apply(true, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		HammerComp.bGroundOffset.Clear(this);
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		HammerComp.HoldHammerComp.Hammer.FauxRotateComp.ApplyForce(Owner.ActorCenterLocation, Owner.ActorVelocity * 3);
	}
}