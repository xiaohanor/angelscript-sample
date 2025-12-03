class UPinballPredictionMagnetAttachedCapability : UPinballMagnetDronePredictionCapability
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

		if(!SyncData.AttachedData.AttachedData.IsValid())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Proxy.AttachedComp.IsAttached())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(MagnetDroneTags::BlockedWhileAttached, this);

		FPinballPredictionSyncedData SyncData;
		float CrumbTime = 0;
		SyncComp.GetLatestAvailableData(SyncData, CrumbTime);

		FMagnetDroneAttachmentParams AttachedParams;
		AttachedParams.AttractionStartedParams.TimeUntilArrival = 0.2;
		AttachedParams.Location = SyncData.AttachedData.AttachedData.GetInitialTargetLocation();
		AttachedParams.Normal = SyncData.AttachedData.AttachedData.GetInitialTargetImpactNormal();
		AttachedParams.AttachToComponent = SyncData.AttachedData.AttachedData.GetAttachComp();
		UMagnetDroneEventHandler::Trigger_Attached(Player, AttachedParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(MagnetDroneTags::BlockedWhileAttached, this);

		UMagnetDroneEventHandler::Trigger_Detached(Player);
	}
}