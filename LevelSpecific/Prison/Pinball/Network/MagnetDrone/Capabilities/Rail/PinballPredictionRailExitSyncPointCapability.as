struct FPinballPredictionRailExitSyncPointDeactivateParams
{
	bool bTimedOut = false;
};

/**
 * Active while we are locally predicting a being in an enter launch point.
 * Mainly serves to trigger event handlers.
 */
class UPinballPredictionRailExitSyncPointCapability : UPinballMagnetDronePredictionCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	UPinballBallComponent BallComp;

	UPinballProxyRailPredictionComponent ProxyRailComp;

	bool bHasReceivedPredictedLaunchTime = false;

	APinballRail Rail = nullptr;
	UPinballRailSyncPoint ExitSyncPoint = nullptr;
    EPinballRailHeadOrTail ExitSide = EPinballRailHeadOrTail::None;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		if(HasControl())
			return;
		
		Super::Setup();

		BallComp = UPinballBallComponent::Get(Player);
		ProxyRailComp = UPinballProxyRailPredictionComponent::Get(Proxy);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		if(ProxyRailComp.ExitSyncPointState != EPinballBallRailSyncPointState::Waiting)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPinballPredictionRailExitSyncPointDeactivateParams& Params) const
	{
		if(ActiveDuration > Pinball::Rail::GetSyncPointTimeOutDuration())
		{
			Params.bTimedOut = true;
			return true;
		}

		if(ProxyRailComp.ExitSyncPointState == EPinballBallRailSyncPointState::Waiting)
			return false;

		const FPinballPredictionSyncedData SyncedData = PredictionComp.GetLatestSyncedData(false);
		if(Time::OtherSideCrumbTrailSendTimePrediction > SyncedData.RailData.PredictedExitSyncPointLaunchTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Rail = ProxyRailComp.Rail;
		ExitSyncPoint = ProxyRailComp.ExitSyncPoint;
		ExitSide = ProxyRailComp.ExitSide;

		Pinball::Rail::TriggerEnterSyncPointEvent(BallComp, Rail, ExitSyncPoint, ExitSide);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPinballPredictionRailExitSyncPointDeactivateParams Params)
	{
		if(Params.bTimedOut)
		{
			// We are stuck in the prediction, stop it!
			ProxyRailComp.EnterSyncPointState = EPinballBallRailSyncPointState::NoSyncPoint;
			Pinball::Rail::TriggerPredictionCancelledSyncPointEvent(BallComp, Rail, ExitSyncPoint);
		}
		else
		{
			if(!bHasReceivedPredictedLaunchTime)
			{
				Pinball::Rail::TriggerPredictionReceivedLaunchTimeSyncPointEvent(Rail, ExitSyncPoint, 0);
			}

			Pinball::Rail::TriggerLaunchEvent(BallComp, Rail, ExitSide, EPinballRailEnterOrExit::Exit);
			Pinball::Rail::TriggerExitSyncPointEvent(BallComp, Rail, ExitSyncPoint, ExitSide);
		}

		Rail = nullptr;
		ExitSyncPoint = nullptr;
		ExitSide = EPinballRailHeadOrTail::None;

		bHasReceivedPredictedLaunchTime = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bHasReceivedPredictedLaunchTime)
		{
			const FPinballPredictionSyncedData SyncedData = PredictionComp.GetLatestSyncedData(false);
			const bool bIsPredictingLaunch = SyncedData.RailData.IsExitSyncPointLaunching(float32(Time::OtherSideCrumbTrailSendTimePrediction));

			if(bIsPredictingLaunch)
			{
				const float TimeUntilLaunch = SyncedData.RailData.PredictedExitSyncPointLaunchTime - Time::OtherSideCrumbTrailSendTimePrediction;
				Pinball::Rail::TriggerPredictionReceivedLaunchTimeSyncPointEvent(Rail, ExitSyncPoint, TimeUntilLaunch);
				bHasReceivedPredictedLaunchTime = true;
			}
		}
	}
};