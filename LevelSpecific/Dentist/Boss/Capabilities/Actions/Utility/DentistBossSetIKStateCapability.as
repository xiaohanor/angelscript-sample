struct FDentistBossSetIKStateActivationParams
{
	bool bOnlyClear = false;
	EDentistIKState NewState;
	EInstigatePriority Prio;
}

class UDentistBossSetIKStateCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FDentistBossSetIKStateActivationParams Params;

	ADentistBoss Dentist;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossSetIKStateActivationParams InParams)
	{
		Params = InParams;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Dentist.ClearIKState(Dentist);
		if(!Params.bOnlyClear)
			Dentist.CurrentIKState.Apply(Params.NewState, Dentist, Params.Prio);

		DetachFromActionQueue();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};