class UPinballProxyRailEnterSyncPointPredictability : UPinballMagnetDronePredictability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 90; // Before RailMovement

	UPinballProxyRailPredictionComponent ProxyRailComp;
	UPinballMagnetDroneRailComponent ControlRailComp;

	UPinballProxyMovementComponent ProxyMoveComp;
	UPinballProxyTeleportingMovementData MoveData;

	FHazeAcceleratedVector AccOffset;

	void Setup(APinballProxy InProxy) override
	{
		Super::Setup(InProxy);

		ProxyRailComp = UPinballProxyRailPredictionComponent::Get(Proxy);
		ControlRailComp = UPinballMagnetDroneRailComponent::Get(Pinball::GetBallPlayer());

		ProxyMoveComp = UPinballProxyMovementComponent::Get(Proxy);
		MoveData = ProxyMoveComp.SetupMovementData(UPinballProxyTeleportingMovementData);
	}

	void InitPredictabilityState() override
	{
		// Initialize rail state from control side
		Super::InitPredictabilityState();
	}

	bool ShouldActivate(bool bInit) override
	{
		if(ProxyMoveComp.ProxyHasMovedThisFrame())
			return false;

		// Only when in a rail
		if (!ProxyRailComp.IsInAnyRail())
			return false;

		if (!ProxyRailComp.Rail.ShouldSyncWhenEntering(ProxyRailComp.EnterSide))
			return false;

		// We have already synced at the enter sync point
		if (ProxyRailComp.EnterSyncPointState == EPinballBallRailSyncPointState::FinishedWaiting)
			return false;

		return true;
	}

	bool ShouldDeactivate() override
	{
		if(ProxyRailComp.EnterSyncPointState != EPinballBallRailSyncPointState::Waiting)
			return true;

		return false;
	}

	void OnActivated(bool bInit) override
	{
		ProxyRailComp.EnterSyncPointState = EPinballBallRailSyncPointState::Waiting;
		ProxyRailComp.EnterSyncPoint = ProxyRailComp.Rail.GetSyncPoint(ProxyRailComp.EnterSide);

		FVector SyncPointLocation = ProxyRailComp.Rail.GetSyncPointLocation(ProxyRailComp.EnterSide);
		FVector SyncPointDirection = ProxyRailComp.Rail.GetSyncPointDirection(ProxyRailComp.EnterSide, EPinballRailEnterOrExit::Enter);

		FVector CurrentLocation = Proxy.ActorLocation;
		FVector CurrentVelocity = Proxy.ActorVelocity;
		if(CurrentLocation.IsAbovePlane(FPlane(SyncPointLocation, SyncPointDirection)))
		{
			CurrentLocation = CurrentLocation.PointPlaneProject(SyncPointLocation, SyncPointDirection);
			CurrentVelocity = CurrentVelocity.VectorPlaneProject(SyncPointDirection);
		}

		if(CurrentVelocity.DotProduct(SyncPointLocation - CurrentLocation) < 0)
			CurrentVelocity = FVector::ZeroVector;

		FVector Offset = CurrentLocation - SyncPointLocation;
		AccOffset.SnapTo(Offset, CurrentVelocity);
	}

	void OnDeactivated() override
	{
		ProxyRailComp.EnterSyncPointState = EPinballBallRailSyncPointState::FinishedWaiting;
		ProxyRailComp.Speed = ProxyRailComp.Rail.GetEnterSpeed(ProxyMoveComp.Velocity, ProxyRailComp.EnterSide);
	}

	void TickActive(float DeltaTime) override
	{	
		if(!ProxyMoveComp.ProxyPrepareMove(MoveData, DeltaTime = DeltaTime))
			return;

		const FVector SyncPointLocation = ProxyRailComp.Rail.GetSyncPointLocation(ProxyRailComp.EnterSide);

		AccOffset.AccelerateTo(FVector::ZeroVector, Pinball::Movement::RailInterpToSyncPointDuration, DeltaTime);
		FVector TargetLocation = SyncPointLocation + AccOffset.Value;

		MoveData.AddDeltaFromMoveTo(TargetLocation);

		ProxyMoveComp.ApplyMove(MoveData);
	}

#if !RELEASE
	void LogActive(FTemporalLog SubframeLog) const override
	{
		Super::LogActive(SubframeLog);

		FVector SyncPointLocation = ProxyRailComp.Rail.GetSyncPointLocation(ProxyRailComp.EnterSide);

		SubframeLog
			.Value("Speed", ProxyRailComp.Speed)
			.Sphere("PreviousLocation", Proxy.ActorLocation, MagnetDrone::Radius, FLinearColor::Red)
			.Value("DistanceAlongSpline", ProxyRailComp.DistanceAlongSpline)
			.DirectionalArrow("AccOffset;Value", SyncPointLocation, AccOffset.Value)
			.DirectionalArrow("AccOffset;Velocity", SyncPointLocation + AccOffset.Value, AccOffset.Velocity)
		;
	}
#endif
}
