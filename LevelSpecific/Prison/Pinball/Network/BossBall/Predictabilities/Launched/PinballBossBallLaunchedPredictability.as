class UPinballBossBallLaunchedPredictability : UPinballBossBallPredictability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 102;

	// Proxy
	UPinballBossBallProxyLaunchedComponent ProxyLaunchedComp;
	UPinballProxyMovementComponent ProxyMoveComp;

	void Setup(APinballProxy InProxy) override
	{
		Super::Setup(InProxy);

		ProxyLaunchedComp = UPinballBossBallProxyLaunchedComponent::Get(Proxy);
		ProxyMoveComp = UPinballProxyMovementComponent::Get(Proxy);
	}

	void InitPredictabilityState() override
	{
		if(!ProxyLaunchedComp.WasLaunchedThisFrame() && ProxyLaunchedComp.WasLaunched())
		{
			if(!ensure(ProxyLaunchedComp.WasLaunched() || bIsActive))
				return;

			// We have already been launched, silently activate
			bIsActive = true;
			ProxyMoveComp.AddMovementIgnoresActor(ProxyLaunchedComp, ProxyLaunchedComp.LaunchData.LaunchedBy.Owner);
		}
		else
		{
			Super::InitPredictabilityState();
		}
	}
	
#if !RELEASE
	void LogState(FTemporalLog SubframeLog) const override
	{
		Super::LogState(SubframeLog);
		
		SubframeLog.Value(f"LaunchedFrame", ProxyLaunchedComp.LaunchedFrame)
			.Value(f"TickFrameNumber", Proxy.SubframeNumber)
			.Value(f"WasLaunchedThisFrame()", ProxyLaunchedComp.WasLaunchedThisFrame())
		;
	}
#endif

	bool ShouldActivate(bool bInit) override
	{
		if(!ProxyLaunchedComp.WasLaunchedThisFrame())
			return false;

		return true;
	}

	bool ShouldDeactivate() override
	{
		if(ProxyLaunchedComp.WasLaunchedThisFrame())
			return false;

		if(!ProxyLaunchedComp.WasLaunched())
			return true;

		if(!Pinball::IsLaunching(
			ProxyMoveComp.Velocity, 
			ProxyLaunchedComp.GetLaunchDirection(), 
			ProxyLaunchedComp.LaunchData.LaunchedBy,
			ProxyLaunchedComp.LaunchedTime, 
			Proxy.TickGameTime)
		)
			return true;

		if(ProxyLaunchedComp.LaunchedTime - Proxy.TickGameTime > 0.1)
		{
			if(ProxyMoveComp.HasAnyValidBlockingImpacts())
				return true;
		}

		return false;
	}

	void OnActivated(bool bInit) override
	{
		ProxyLaunchedComp.LaunchedTime = Proxy.TickGameTime;

		ProxyLaunchedComp.ConsumeLaunch();

		ProxyLaunchedComp.bIsLaunched = true;
	}

	void OnDeactivated() override
	{
		ProxyMoveComp.RemoveMovementIgnoresActor(this);
		ProxyLaunchedComp.ResetLaunch();
	}
	
	void TickActive(float DeltaTime) override
	{
		if(ProxyLaunchedComp.HasLaunchToConsume())
		{
			ProxyLaunchedComp.ConsumeLaunch();
		}

		ProxyMoveComp.ClearCurrentGroundedState();
	}

	void PostPrediction() override
	{
		Super::PostPrediction();

		if(bIsActive)
		{
			// Make sure that we don't keep ignoring a movement actor
			ProxyMoveComp.RemoveMovementIgnoresActor(ProxyLaunchedComp);
		}
	}
}