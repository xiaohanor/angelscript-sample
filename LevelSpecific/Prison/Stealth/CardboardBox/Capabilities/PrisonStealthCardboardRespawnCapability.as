class UPrisonStealthCardboardRespawnCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	APrisonStealthCardboardBox CardboardBox;

	const float RespawnDelay = 2.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CardboardBox = Cast<APrisonStealthCardboardBox>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPrisonStealthCardboardSimulatedActivateParams& Params) const
	{
		if(CardboardBox.DesiredState != EPrisonStealthCardboardBoxState::Respawn)
			return false;

		Params.Impulse = CardboardBox.InitialImpulse;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CardboardBox.bAllowRespawning)
			return false;

		if(CardboardBox.DesiredState != EPrisonStealthCardboardBoxState::Respawn)
			return true;

		if(CardboardBox.CurrentState != EPrisonStealthCardboardBoxState::Respawn)
			return true;

		if(ActiveDuration > RespawnDelay)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPrisonStealthCardboardSimulatedActivateParams Params)
	{
		CardboardBox.ApplyState(EPrisonStealthCardboardBoxState::Respawn);

		UPrisonStealthCardboardBoxEventHandler::Trigger_OnCardboardDisappear(CardboardBox);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CardboardBox.Reset();

		UPrisonStealthCardboardBoxEventHandler::Trigger_OnCardboardRespawn(CardboardBox);
	}
};