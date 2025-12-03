struct FDentistBossSetStateActivationParams
{
	EDentistBossState NewState;
}

class UDentistBossSetStateCapability : UHazeActionQueueCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FDentistBossSetStateActivationParams Params;

	ADentistBoss Dentist;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FDentistBossSetStateActivationParams InParams)
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
		Dentist.CurrentState = Params.NewState;
		Dentist.OnStateProgressedTo.Broadcast(Params.NewState);
		FDentistBossEffectHandlerOnSwitchedStateParams EffectHandlerParams;
		EffectHandlerParams.NewState = Params.NewState;
		UDentistBossEffectHandler::Trigger_OnSwitchedState(Dentist, EffectHandlerParams);

		DetachFromActionQueue();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};