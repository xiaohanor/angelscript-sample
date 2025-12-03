class UPinballProxyRailExitSyncPointPredictability : UPinballMagnetDronePredictability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 110;

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
		if(!ProxyRailComp.IsInAnyRail())
			return false;

		// RailMovement decides when we enter the exit sync point
		if(ProxyRailComp.ExitSyncPointState != EPinballBallRailSyncPointState::Waiting)
			return false;

		return true;
	}

	bool ShouldDeactivate() override
	{
		if(ProxyRailComp.ExitSyncPointState != EPinballBallRailSyncPointState::Waiting)
			return true;

		return false;
	}

	void OnActivated(bool bInit) override
	{
		ProxyRailComp.ExitSyncPointState = EPinballBallRailSyncPointState::Waiting;
		ProxyRailComp.ExitSyncPoint = ProxyRailComp.Rail.GetSyncPoint(ProxyRailComp.ExitSide);

		FVector SyncPointLocation = ProxyRailComp.Rail.GetSyncPointLocation(ProxyRailComp.ExitSide);
		FVector SyncPointDirection = ProxyRailComp.Rail.GetSyncPointDirection(ProxyRailComp.ExitSide, EPinballRailEnterOrExit::Exit);

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
		ProxyRailComp.ExitSyncPointState = EPinballBallRailSyncPointState::FinishedWaiting;
		
		const FVector ExitVelocity = ProxyRailComp.Rail.GetExitVelocity(ProxyRailComp.Speed, ProxyRailComp.ExitSide).VectorPlaneProject(FVector::ForwardVector);
		Proxy.SetActorVelocity(ExitVelocity);

		ProxyRailComp.Reset(true);
	}

	void TickActive(float DeltaTime) override
	{	
		if(!ProxyMoveComp.ProxyPrepareMove(MoveData, DeltaTime))
			return;

		const FVector SyncPointLocation = ProxyRailComp.Rail.GetSyncPointLocation(ProxyRailComp.ExitSide);

		AccOffset.AccelerateTo(FVector::ZeroVector, Pinball::Movement::RailInterpToSyncPointDuration, DeltaTime);
		FVector TargetLocation = SyncPointLocation + AccOffset.Value;

		MoveData.AddDeltaFromMoveTo(TargetLocation);

		ProxyMoveComp.ApplyMove(MoveData);
	}

#if !RELEASE
	void LogActive(FTemporalLog SubframeLog) const override
	{
		Super::LogActive(SubframeLog);

		SubframeLog
			.Value("Speed", ProxyRailComp.Speed)
			.Sphere("PreviousLocation", Proxy.ActorLocation, MagnetDrone::Radius, FLinearColor::Red)
			.Value("DistanceAlongSpline", ProxyRailComp.DistanceAlongSpline)
		;
	}
#endif
}
