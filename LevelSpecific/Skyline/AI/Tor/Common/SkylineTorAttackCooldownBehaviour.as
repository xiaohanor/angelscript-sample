
class USkylineTorAttackCooldownBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	USkylineTorBehaviourComponent TorBehaviourComp;

	float Duration = 1.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		TorBehaviourComp = USkylineTorBehaviourComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(Time::GetGameTimeSince(TorBehaviourComp.CooldownTime) > 1)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Duration)
			return true;
		return false;
	}
}