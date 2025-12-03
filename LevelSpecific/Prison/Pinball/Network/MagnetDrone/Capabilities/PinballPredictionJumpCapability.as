class UPinballPredictionJumpCapability : UPinballMagnetDronePredictionCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UPinballPredictionSyncComponent SyncComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		if(HasControl())
			return;

		Super::Setup();

		SyncComp = UPinballPredictionSyncComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		FPinballPredictionSyncedData SyncData;
		float CrumbTime = 0;
		SyncComp.GetLatestAvailableData(SyncData, CrumbTime);

		if(!SyncData.MovementData.bIsJumping)
			return false;

		if(Proxy.MoveComp.IsOnAnyGround())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Proxy.MoveComp.IsOnAnyGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UMagnetDroneEventHandler::Trigger_JumpStart(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMagnetDroneEventHandler::Trigger_JumpStop(Player);
	}
};