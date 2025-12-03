struct FDentistBossQueueToggleLoopingActivationParams
{
	int QueueIndex;
	bool bToggleOn;
}

class UDentistBossQueueToggleLoopingCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FDentistBossQueueToggleLoopingActivationParams Params;

	ADentistBoss Dentist;
	
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
			}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossQueueToggleLoopingActivationParams InParams)
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
		Dentist.ActionQueueComps[Params.QueueIndex].SetLooping(Params.bToggleOn);
		DetachFromActionQueue();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};