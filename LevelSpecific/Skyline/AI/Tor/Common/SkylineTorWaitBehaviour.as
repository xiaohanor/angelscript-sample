
class USkylineTorWaitBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;
	float Duration = 1;

	USkylineTorPlayerCollisionComponent CollisionComp;

	USkylineTorWaitBehaviour(float WaitDuration)
	{
		Duration = WaitDuration;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		CollisionComp = USkylineTorPlayerCollisionComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
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

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		// CollisionComp.bEnabled = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		// CollisionComp.bEnabled = false;
	}
}