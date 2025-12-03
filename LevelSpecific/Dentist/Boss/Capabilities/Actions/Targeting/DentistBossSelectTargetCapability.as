struct FDentistBossSelectTargetActivationParams
{
	AHazePlayerCharacter TargetPlayer; 
}

class UDentistBossSelectTargetCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;

	UDentistBossTargetComponent TargetComp;

	FDentistBossSelectTargetActivationParams Params;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);

		TargetComp = UDentistBossTargetComponent::GetOrCreate(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossSelectTargetActivationParams InParams)
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
		TargetComp.Target.Clear(Dentist);
		if(Params.TargetPlayer != nullptr)
			TargetComp.Target.Apply(Params.TargetPlayer, Dentist, EInstigatePriority::Normal);
		
		DetachFromActionQueue();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};