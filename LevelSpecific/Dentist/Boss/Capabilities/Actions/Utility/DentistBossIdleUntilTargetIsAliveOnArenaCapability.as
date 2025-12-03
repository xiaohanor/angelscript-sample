struct FDentistBossIdleUntilTargetIsAliveOnArenaParams
{
	bool bGetFromTargetComp = false;	
	AHazePlayerCharacter Target;
}

class UDentistBossIdleUntilTargetIsAliveOnArenaCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBoss Dentist;
	UDentistBossTargetComponent TargetComp;

	FDentistBossIdleUntilTargetIsAliveOnArenaParams Params;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		TargetComp = UDentistBossTargetComponent::Get(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossIdleUntilTargetIsAliveOnArenaParams InParams)
	{
		Params = InParams;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		AHazePlayerCharacter Target = Params.Target;
		if(Params.bGetFromTargetComp)
			Target = TargetComp.Target.Get();

		if(!TargetComp.IsOnCake[Target])
			return false;

		if(Target.IsPlayerDeadOrRespawning())
			return false;

		return true;
	}
};