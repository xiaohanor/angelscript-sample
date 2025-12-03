class UPinballPredictionDashCapability : UPinballMagnetDronePredictionCapability
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

		if(!SyncData.MovementData.bIsDashing)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		FPinballPredictionSyncedData SyncData;
		float CrumbTime = 0;
		SyncComp.GetLatestAvailableData(SyncData, CrumbTime);

		if(!SyncData.MovementData.bIsDashing)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UDroneEventHandler::Trigger_DashStart(Player);
		UMagnetDroneEventHandler::Trigger_MagnetDroneDash(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UDroneEventHandler::Trigger_DashStop(Player);
	}
}