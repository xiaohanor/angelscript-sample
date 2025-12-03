class UScorpionSiegeOperatorOperatingWeaponBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UScorpionSiegeOperatorOperationComponent OperationComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		OperationComp = UScorpionSiegeOperatorOperationComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!OperationComp.bOperating || !OperationComp.TargetWeapon.HealthComp.IsAlive())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!OperationComp.bOperating || !OperationComp.TargetWeapon.HealthComp.IsAlive())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		DestinationComp.RotateTowards(OperationComp.TargetWeapon.FocusLocation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AnimComp.RequestFeature(LocomotionFeatureAIScorpionSiegeOperatorTags::Operate, EBasicBehaviourPriority::Medium, this);
	}
}