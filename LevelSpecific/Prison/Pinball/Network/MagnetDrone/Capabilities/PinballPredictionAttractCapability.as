struct FPinballPredictionAttractDeactivateParams
{
	bool bFinished = false;
};

class UPinballPredictionAttractCapability : UPinballMagnetDronePredictionCapability
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

		if(!SyncData.AttractionData.AttractionTarget.IsValidTarget())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPinballPredictionAttractDeactivateParams& Params) const
	{
		if(Proxy.AttachedComp.IsAttached())
		{
			Params.bFinished = true;
			return true;
		}

		if(!Proxy.AttractionComp.IsAttracting())
		{
			Params.bFinished = Proxy.AttachedComp.IsAttached();
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FMagnetDroneAttractionStartedParams EventData;
		EventData.TimeUntilArrival = 0.2;
		UMagnetDroneEventHandler::Trigger_AttractionStarted(Player, EventData);

		Player.BlockCapabilities(MagnetDroneTags::BlockedWhileAttraction, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPinballPredictionAttractDeactivateParams Params)
	{
		Player.UnblockCapabilities(MagnetDroneTags::BlockedWhileAttraction, this);

		if(!Params.bFinished)
		{
			UMagnetDroneEventHandler::Trigger_AttractionCanceled(Player);
		}
	}
};