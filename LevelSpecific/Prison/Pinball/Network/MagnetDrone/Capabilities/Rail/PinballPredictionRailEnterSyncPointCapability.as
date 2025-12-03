struct FPinballPredictionRailEnterSyncPointDeactivateParams
{
	bool bTimedOut = false;
};

/**
 * Active while we are locally predicting a being in an enter launch point.
 * Mainly serves to trigger event handlers.
 */
class UPinballPredictionRailEnterSyncPointCapability : UPinballMagnetDronePredictionCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	UPinballBallComponent BallComp;

	UPinballProxyRailPredictionComponent ProxyRailComp;

	bool bHasReceivedPredictedLaunchTime = false;

	APinballRail Rail = nullptr;
	UPinballRailSyncPoint EnterSyncPoint = nullptr;
    EPinballRailHeadOrTail EnterSide = EPinballRailHeadOrTail::None;

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

		if(ProxyRailComp.EnterSyncPointState != EPinballBallRailSyncPointState::Waiting)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPinballPredictionRailEnterSyncPointDeactivateParams& Params) const
	{
		if(ActiveDuration > Pinball::Rail::GetSyncPointTimeOutDuration())
		{
			Params.bTimedOut = true;
			return true;
		}

		if(ProxyRailComp.EnterSyncPointState == EPinballBallRailSyncPointState::Waiting)
			return false;

		const FPinballPredictionSyncedData SyncedData = PredictionComp.GetLatestSyncedData(false);
		if(Time::OtherSideCrumbTrailSendTimePrediction > SyncedData.RailData.PredictedEnterSyncPointLaunchTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Rail = ProxyRailComp.Rail;
		EnterSyncPoint = ProxyRailComp.EnterSyncPoint;
		EnterSide = ProxyRailComp.EnterSide;

		Pinball::Rail::TriggerEnterSyncPointEvent(BallComp, Rail, EnterSyncPoint, EnterSide);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPinballPredictionRailEnterSyncPointDeactivateParams Params)
	{
		if(Params.bTimedOut)
		{
			// We are stuck in the prediction, stop it!
			ProxyRailComp.EnterSyncPointState = EPinballBallRailSyncPointState::NoSyncPoint;
			Pinball::Rail::TriggerPredictionCancelledSyncPointEvent(BallComp, Rail, EnterSyncPoint);
		}
		else
		{
			if(!bHasReceivedPredictedLaunchTime)
			{
				Pinball::Rail::TriggerPredictionReceivedLaunchTimeSyncPointEvent(Rail, EnterSyncPoint, 0);
			}

			Pinball::Rail::TriggerLaunchEvent(BallComp, Rail, EnterSide, EPinballRailEnterOrExit::Enter);
			Pinball::Rail::TriggerExitSyncPointEvent(BallComp, Rail, EnterSyncPoint, EnterSide);
		}

		Rail = nullptr;
		EnterSyncPoint = nullptr;
		EnterSide = EPinballRailHeadOrTail::None;

		bHasReceivedPredictedLaunchTime = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bHasReceivedPredictedLaunchTime)
		{
			const FPinballPredictionSyncedData SyncedData = PredictionComp.GetLatestSyncedData(false);

			const bool bIsPredictingLaunch = SyncedData.RailData.IsEnterSyncPointLaunching(Time::OtherSideCrumbTrailSendTimePrediction);

			if(bIsPredictingLaunch)
			{
				const float TimeUntilLaunch = SyncedData.RailData.PredictedEnterSyncPointLaunchTime - Time::OtherSideCrumbTrailSendTimePrediction;
				Pinball::Rail::TriggerPredictionReceivedLaunchTimeSyncPointEvent(Rail, EnterSyncPoint, TimeUntilLaunch);
				bHasReceivedPredictedLaunchTime = true;
			}
		}
	}
};