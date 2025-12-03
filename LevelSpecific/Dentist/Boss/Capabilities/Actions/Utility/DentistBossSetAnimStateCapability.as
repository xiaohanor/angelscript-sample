struct FDentistBossSetAnimStateActivationParams
{
	bool bOnlyClear = false;
	EDentistBossAnimationState NewState;
	EInstigatePriority Prio;
}

class UDentistBossSetAnimStateCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FDentistBossSetAnimStateActivationParams Params;

	ADentistBoss Dentist;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossSetAnimStateActivationParams InParams)
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
		Dentist.CurrentAnimationState.Clear(Dentist);
		if(!Params.bOnlyClear)
			Dentist.CurrentAnimationState.Apply(Params.NewState, Dentist, Params.Prio);

		DetachFromActionQueue();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};