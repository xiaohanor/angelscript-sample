class UGravityBikeSplineBikeEnemyDriverGrabbedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AGravityBikeSplineBikeEnemyDriver Driver;
	UGravityBikeWhipGrabTargetComponent GrabTargetComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Driver = Cast<AGravityBikeSplineBikeEnemyDriver>(Owner);
		GrabTargetComp = UGravityBikeWhipGrabTargetComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!GrabTargetComp.IsGrabbed())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!GrabTargetComp.IsGrabbed())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Driver.State = EGravityBikeSplineBikeEnemyDriverState::Grabbed;
		Driver.DetachFromActor();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};