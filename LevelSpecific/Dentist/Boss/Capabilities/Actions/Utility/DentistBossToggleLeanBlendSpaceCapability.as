struct FDentistBossToggleLeanBlendSpaceActivationParams
{
	bool bToggleOn = false;
}

class UDentistBossToggleLeanBlendSpaceCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FDentistBossToggleLeanBlendSpaceActivationParams Params;

	ADentistBoss Dentist;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossToggleLeanBlendSpaceActivationParams InParams)
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
		Dentist.UseLeanBlendSpace.Clear(this);
		Dentist.UseLeanBlendSpace.Apply(Params.bToggleOn, this, EInstigatePriority::Normal);

		DetachFromActionQueue();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};