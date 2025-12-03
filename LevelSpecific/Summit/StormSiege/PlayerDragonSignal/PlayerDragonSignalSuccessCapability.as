class UPlayerDragonSignalSuccessCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerDragonSignalComponent UserComp;

	bool bCompletedSignal;

	float SignalTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UPlayerDragonSignalComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.bSignalSuccessful)
			return false;

		if (bCompletedSignal)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (SignalTime <= 0.0)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SignalTime = UserComp.SignalTime;
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		bCompletedSignal = true;
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SignalTime -= DeltaTime;
	}
};