class UPinballBossBallMovePredictability : UPinballBossBallPredictability
{
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 93;

	UPinballBossBallProxyMovementComponent ProxyMoveComp;
	UPinballMagnetDroneMovementData MoveData;

	void Setup(APinballProxy InProxy) override
	{
		Super::Setup(InProxy);

		ProxyMoveComp = UPinballBossBallProxyMovementComponent::Get(Proxy);
		MoveData = ProxyMoveComp.SetupMovementData(UPinballMagnetDroneMovementData);
	}

	bool ShouldActivate(bool bInit) override
	{
		if(ProxyMoveComp.ProxyHasMovedThisFrame())
			return false;

		if(ProxyMoveComp.IsInAir())
			return false;

		return true;
	}

	bool ShouldDeactivate() override
	{
		if(ProxyMoveComp.ProxyHasMovedThisFrame())
			return true;

		if(ProxyMoveComp.IsInAir())
			return true;

		return false;
	}

	void TickActive(float DeltaTime) override
	{
		if(!ProxyMoveComp.ProxyPrepareMove(MoveData, DeltaTime))
			return;

		FVector Delta;
		FVector Velocity = ProxyMoveComp.Velocity;
		Pinball::GroundMoveSimulation::Tick(
			Delta,
			Velocity,
			0,
			ProxyMoveComp.IsOnWalkableGround(),
			ProxyMoveComp.GroundContact.Normal,
			Pinball::GetWorldUp(),
			BossBall.MovementSettings,
			DeltaTime
		);

		MoveData.AddDeltaWithCustomVelocity(Delta, Velocity);

		// Also add world impulses
		MoveData.AddPendingImpulses();

		ProxyMoveComp.ApplyMove(MoveData);
	}
};