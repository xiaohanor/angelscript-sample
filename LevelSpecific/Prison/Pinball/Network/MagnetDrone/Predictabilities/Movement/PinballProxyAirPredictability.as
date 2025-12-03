class UPinballProxyAirPredictability : UPinballMagnetDronePredictability
{
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 93;

	UPinballMovementSettings MovementSettings;
	UPinballProxyMovementComponent MoveComp;
	UPinballMagnetDroneMovementData MoveData;

	void Setup(APinballProxy InProxy) override
	{
		Super::Setup(InProxy);

		MovementSettings = UPinballMovementSettings::GetSettings(MagnetDrone);
		MoveComp = UPinballProxyMovementComponent::Get(Proxy);
		MoveData = MoveComp.SetupMovementData(UPinballMagnetDroneMovementData);
	}

	bool ShouldActivate(bool bInit) override
	{
		if(MoveComp.ProxyHasMovedThisFrame())
			return false;

		if(!MoveComp.IsInAir())
			return false;

		if(MagnetDrone.IsPlayerDead())
			return false;

		return true;
	}

	bool ShouldDeactivate() override
	{
		if(MoveComp.ProxyHasMovedThisFrame())
			return true;

		if(!MoveComp.IsInAir())
			return true;

		if(MagnetDrone.IsPlayerDead())
			return true;

		return false;
	}

	void TickActive(float DeltaTime) override
	{
		if(!MoveComp.ProxyPrepareMove(MoveData, DeltaTime))
			return;

		FVector Delta;
		FVector Velocity = MoveComp.Velocity;
		Pinball::AirMoveSimulation::Tick(
			Delta,
			Velocity,
			Proxy.LaunchedComp.bIsLaunched,
			Proxy.TickHorizontalInput, 
			MovementSettings, 
			DeltaTime
		);

		MoveData.AddDeltaWithCustomVelocity(Delta, Velocity);

		// Also add world impulses
		MoveData.AddPendingImpulses();
	
		MoveComp.ApplyMove(MoveData);
	}

#if !RELEASE
	void LogActive(FTemporalLog SubframeLog) const override
	{
		Super::LogActive(SubframeLog);

		SubframeLog.DirectionalArrow(f"Velocity", Proxy.ActorLocation, MoveComp.Velocity);
	}
#endif
}
