class UPinballBossBallAirMovePredictability : UPinballBossBallPredictability
{
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 93;
	
	// Proxy
	UPinballBossBallProxyLaunchedComponent ProxyLaunchedComp;
	UPinballBossBallProxyMovementComponent ProxyMoveComp;
	UPinballMagnetDroneMovementData MoveData; 

	void Setup(APinballProxy InProxy) override
	{
		Super::Setup(InProxy);

		ProxyLaunchedComp = UPinballBossBallProxyLaunchedComponent::Get(Proxy);
		ProxyMoveComp = UPinballBossBallProxyMovementComponent::Get(Proxy);
		MoveData = ProxyMoveComp.SetupMovementData(UPinballMagnetDroneMovementData);
	}

	bool ShouldActivate(bool bInit) override
	{
		if(ProxyMoveComp.ProxyHasMovedThisFrame())
			return false;

		if(!ProxyMoveComp.IsInAir())
			return false;

		return true;
	}

	bool ShouldDeactivate() override
	{
		if(ProxyMoveComp.ProxyHasMovedThisFrame())
			return true;

		if(!ProxyMoveComp.IsInAir())
			return true;

		return false;
	}

	void TickActive(float DeltaTime) override
	{	
		if(!ProxyMoveComp.ProxyPrepareMove(MoveData, DeltaTime))
			return;

		FVector Delta;
		FVector Velocity = ProxyMoveComp.Velocity;
		Pinball::AirMoveSimulation::Tick(
			Delta,
			Velocity,
			ProxyLaunchedComp.bIsLaunched,
			0,
			BossBall.MovementSettings,
			DeltaTime
		);

		MoveData.AddDeltaWithCustomVelocity(Delta, Velocity);

		// Also add world impulses
		MoveData.AddPendingImpulses();

		ProxyMoveComp.ApplyMove(MoveData);
	}
};