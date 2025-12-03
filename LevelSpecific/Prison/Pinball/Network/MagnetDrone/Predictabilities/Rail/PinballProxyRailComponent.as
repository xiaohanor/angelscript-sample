UCLASS(NotBlueprintable, NotPlaceable)
class UPinballProxyRailPredictionComponent : UPinballMagnetDroneProxyComponent
{
	default ControlComponentClass = UPinballMagnetDroneRailComponent;

	/**
	 * Synced data
	 * Initially the same as Control, but will be modified during the prediction
	 */
	APinballRail Rail = nullptr;
	bool bIsInRail = false;
    float Speed = 0.0;
	float DistanceAlongSpline = 0.0;

    EPinballRailHeadOrTail EnterSide = EPinballRailHeadOrTail::None;
    EPinballRailHeadOrTail ExitSide = EPinballRailHeadOrTail::None;
	
	UPinballRailSyncPoint EnterSyncPoint = nullptr;
	EPinballBallRailSyncPointState EnterSyncPointState = EPinballBallRailSyncPointState::NoSyncPoint;

	UPinballRailSyncPoint ExitSyncPoint = nullptr;
	EPinballBallRailSyncPointState ExitSyncPointState = EPinballBallRailSyncPointState::NoSyncPoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
#if !RELEASE
		TEMPORAL_LOG(this, Owner, "PinballProxyRail");
#endif
	}

	void InitComponentState(const UActorComponent ControlComp) override
	{
		Super::InitComponentState(ControlComp);

		const FPinballPredictionSyncedRailData& RailData = Proxy.InitialSyncedData.RailData;

#if !RELEASE
		FTemporalLog InitialLog = Proxy.GetInitialLog().Page(Name.ToString());
		InitialLog.Value("OtherSideCrumbTrailSendTimePrediction", Time::OtherSideCrumbTrailSendTimePrediction);
		InitialLog.Value("IsEnterSyncPointLaunching", RailData.IsEnterSyncPointLaunching(float32(Proxy.InitialGameTime)));
		InitialLog.Value("EnterSyncPointLaunchTime", RailData.PredictedEnterSyncPointLaunchTime);
		InitialLog.Value("IsExitSyncPointLaunching", RailData.IsExitSyncPointLaunching(float32(Proxy.InitialGameTime)));
		InitialLog.Value("ExitSyncPointLaunchTime", RailData.PredictedExitSyncPointLaunchTime);
#endif

		if(EnterSyncPointState == EPinballBallRailSyncPointState::Waiting && RailData.EnterSyncPointState == EPinballBallRailSyncPointState::NoSyncPoint)
		{
			// We have entered the sync point locally, and will await the control side to also enter
			// This times out from UPinballPredictionRailEnterSyncPointCapability
			return;
		}

		if(ExitSyncPointState == EPinballBallRailSyncPointState::Waiting && RailData.ExitSyncPointState == EPinballBallRailSyncPointState::NoSyncPoint)
		{
			// We have entered an exit sync point locally, and will await the control side
			// This times out from UPinballPredictionRailExitSyncPointCapability
			return;
		}

		Rail = RailData.Rail;
		bIsInRail = RailData.bIsInRail;
		Speed = RailData.Speed;
		DistanceAlongSpline = RailData.DistanceAlongSpline;

		EnterSide = RailData.EnterSide;
		ExitSide = RailData.ExitSide;

		EnterSyncPoint = RailData.EnterSyncPoint;
		EnterSyncPointState = RailData.EnterSyncPointState;

		ExitSyncPoint = RailData.ExitSyncPoint;
		ExitSyncPointState = RailData.ExitSyncPointState;
	}

#if !RELEASE
	void LogComponentState(FTemporalLog SubframeLog) const override
	{
		Super::LogComponentState(SubframeLog);
		
		SubframeLog
			.Value("Rail", Rail)
			.Value("bIsInRail", bIsInRail)
			.Value("Speed", Speed)
			.Value("DistanceAlongSpline", DistanceAlongSpline)

			.Value("EnterSide", EnterSide)
			.Value("ExitSide", ExitSide)

			.Value("EnterSyncPoint", EnterSyncPoint)
			.Value("EnterSyncPointState", EnterSyncPointState)

			.Value("ExitSyncPoint", ExitSyncPoint)
			.Value("ExitSyncPointState", ExitSyncPointState)
		;

		if(Rail != nullptr && Proxy.SubframeNumber == 0)
		{
			SubframeLog.RuntimeSpline("Rail Spline", Rail.Spline.BuildRuntimeSplineFromHazeSpline());
		}
	}
#endif
	
    void EnterRail(APinballRail InRail, EPinballRailHeadOrTail InEnterSide)
    {
		check(InRail != nullptr);

        if(!ensure(!IsInAnyRail()))
            return;

        Rail = InRail;
		bIsInRail = true;
		EnterSide = InEnterSide;

		if(InRail.ShouldSyncWhenEntering(InEnterSide))
		{
			EnterSyncPoint = InRail.GetSyncPoint(InEnterSide);
			EnterSyncPointState = EPinballBallRailSyncPointState::Waiting;
		}

		ExitSyncPointState = EPinballBallRailSyncPointState::NoSyncPoint;
    }

    void ExitRail(const APinballRail InRail, EPinballRailHeadOrTail InExitSide)
    {
        if(!ensure(IsInRail(InRail)))
            return;

		if(Rail.ShouldSyncWhenExiting(InExitSide))
		{
			ExitSyncPoint = Rail.GetSyncPoint(InExitSide);
			ExitSyncPointState = EPinballBallRailSyncPointState::Waiting;
		}
		else
		{
			bIsInRail = false;
			ExitSide = InExitSide;
		}
    }

    bool IsInAnyRail() const
    {
        return bIsInRail;
    }

	bool IsInRail(const APinballRail InRail) const
	{
		if(!IsInAnyRail())
			return false;

		return Rail == InRail;
	}

	bool IsWaitingAtSyncPoint() const
	{
		return EnterSyncPointState == EPinballBallRailSyncPointState::Waiting || ExitSyncPointState == EPinballBallRailSyncPointState::Waiting;
	}

	void Reset(bool bIsExit)
	{
		// The rail is not nulled on purpose, because that can cause null refs. Always check bIsInRail instead!
		bIsInRail = false;
		Speed = 0.0;
		DistanceAlongSpline = 0.0;

		EnterSide = EPinballRailHeadOrTail::None;

		EnterSyncPoint = nullptr;
		EnterSyncPointState = EPinballBallRailSyncPointState::NoSyncPoint;

		// Some state should not be reset on exiting, only when fully resetting
		if(bIsExit)
			return;

		ExitSide = EPinballRailHeadOrTail::None;

		ExitSyncPoint = nullptr;
		ExitSyncPointState = EPinballBallRailSyncPointState::FinishedWaiting;
	}
};