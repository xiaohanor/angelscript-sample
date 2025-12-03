
class UPullablePullBackCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPullableComponent PullableComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PullableComp = UPullableComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!PullableComp.bAutomaticallyPullBack)
			return false;
		if (PullableComp.IsAnyPlayerPulling())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!PullableComp.bAutomaticallyPullBack)
			return true;
		if (PullableComp.IsAnyPlayerPulling())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PullableComp.ApplyPullBack(DeltaTime);
	}
};