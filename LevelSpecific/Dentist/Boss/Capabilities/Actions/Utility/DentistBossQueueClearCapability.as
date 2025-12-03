struct FDentistBossQueueClearActivationParams
{
	int QueueIndex;
}

class UDentistBossQueueClearCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FDentistBossQueueClearActivationParams Params;

	ADentistBoss Dentist;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
			}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossQueueClearActivationParams InParams)
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
		Dentist.ActionQueueComps[Params.QueueIndex].Empty();
		DetachFromActionQueue();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};