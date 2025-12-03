class UPinballProxyEnterRailPredictability : UPinballMagnetDronePredictability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 50;

	UPinballMagnetDroneComponent PinballComp;
	UPinballMagnetDroneRailComponent BallRailComp;

	UPinballProxyRailPredictionComponent ProxyRailComp;

	FVector PreviousLocation;

	void Setup(APinballProxy InProxy) override
	{
		Super::Setup(InProxy);

		PinballComp = UPinballMagnetDroneComponent::Get(MagnetDrone);
		BallRailComp = UPinballMagnetDroneRailComponent::Get(MagnetDrone);

		ProxyRailComp = UPinballProxyRailPredictionComponent::Get(Proxy);
	}

	void InitPredictabilityState() override
	{
		PreviousLocation = Proxy.ActorLocation;

		Super::InitPredictabilityState();
	}

	bool ShouldActivate(bool bInit) override
	{
		if(ProxyRailComp.IsInAnyRail())
			return false;

		return true;
	}

	bool ShouldDeactivate() override
	{
		if(ProxyRailComp.IsInAnyRail())
			return true;

		return false;
	}

	void OnActivated(bool bInit) override
	{
		PreviousLocation = Proxy.ActorLocation;
	}

	void TickActive(float DeltaTime) override
	{	
		for(UPinballTriggerComponent TriggerComp : Pinball::GetManager().Triggers)
		{
			// Early cull
			if(TriggerComp.WorldLocation.Distance(Proxy.ActorLocation) > 10000)
				continue;

			auto Rail = Cast<APinballRail>(TriggerComp.Owner);
			if(Rail == nullptr)
				continue;

			if(!TriggerComp.IsInTrigger(PreviousLocation, Proxy.ActorLocation))
				continue;

			const FVector Delta = Proxy.ActorLocation - PreviousLocation;
			const bool bForward = Delta.DotProduct(TriggerComp.UpVector) > 0;

			EPinballRailHeadOrTail EnterSide;
			EPinballRailEnterOrExit Result = Rail.QueryBallPassIsHeadOrTail(TriggerComp, bForward, EnterSide);

			if(Result != EPinballRailEnterOrExit::Enter)
				continue;

			ProxyRailComp.EnterRail(Rail, EnterSide);
			break;
		}

		PreviousLocation = Proxy.ActorLocation;
	}

#if !RELEASE
	void LogActive(FTemporalLog SubframeLog) const override
	{
		Super::LogActive(SubframeLog);
		
		SubframeLog.Arrow(f"Delta", PreviousLocation, Proxy.ActorLocation);
	}
#endif
}
