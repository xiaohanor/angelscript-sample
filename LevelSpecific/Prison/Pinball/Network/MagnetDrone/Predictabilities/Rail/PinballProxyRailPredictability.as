class UPinballProxyRailPredictability : UPinballMagnetDronePredictability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	UPinballProxyRailPredictionComponent ProxyRailComp;

	UPinballProxyMovementComponent ProxyMoveComp;
	UPinballProxyTeleportingMovementData MoveData;

	FHazeAcceleratedVector AccOffset;

	void Setup(APinballProxy InProxy) override
	{
		Super::Setup(InProxy);

		ProxyRailComp = UPinballProxyRailPredictionComponent::Get(Proxy);

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

		if(!ProxyRailComp.IsInAnyRail())
			return false;

		if(ProxyRailComp.IsWaitingAtSyncPoint())
			return false;

		if(ProxyRailComp.ExitSyncPointState != EPinballBallRailSyncPointState::NoSyncPoint)
			return false;

		const FTransform SplineTransform = ProxyRailComp.Rail.Spline.GetClosestSplineWorldTransformToWorldLocation(Proxy.ActorLocation);
		const FVector RelativeLocation = SplineTransform.InverseTransformPositionNoScale(Proxy.ActorLocation);
		AccOffset.SnapTo(RelativeLocation);

		return true;
	}

	bool ShouldDeactivate() override
	{
		if(ProxyMoveComp.ProxyHasMovedThisFrame())
			return true;

		if(ProxyRailComp.ExitSyncPointState != EPinballBallRailSyncPointState::NoSyncPoint)
			return true;

		if(!ProxyRailComp.IsInAnyRail())
			return true;

		return false;
	}

	void OnActivated(bool bInit) override
	{
		if(!bInit)
		{
			ProxyRailComp.Speed = ProxyRailComp.Rail.GetEnterSpeed(ProxyMoveComp.Velocity, ProxyRailComp.EnterSide);
			ProxyRailComp.DistanceAlongSpline = ProxyRailComp.Rail.Spline.GetClosestSplineDistanceToWorldLocation(Proxy.ActorLocation);
		}
	}

	void OnDeactivated() override
	{
		if(!ProxyRailComp.Rail.ShouldSyncWhenExiting(ProxyRailComp.ExitSide))
		{
			// We actually exited the rail, with no sync point
			const FVector ExitVelocity = ProxyRailComp.Rail.GetExitVelocity(ProxyRailComp.Speed, ProxyRailComp.ExitSide).VectorPlaneProject(FVector::ForwardVector);
			Proxy.SetActorVelocity(ExitVelocity);

			ProxyRailComp.Reset(true);
		}
	}

	void TickActive(float DeltaTime) override
	{	
		if(!ProxyMoveComp.ProxyPrepareMove(MoveData, DeltaTime = DeltaTime))
			return;

		const APinballRail Rail = ProxyRailComp.Rail;
		
		FPinballRailMoveSimulation MoveSimulation;
		MoveSimulation.Initialize(Rail);

		bool bReachedEnd = false;
		EPinballRailHeadOrTail ExitSide = EPinballRailHeadOrTail::None;
		FVector NewLocation = MoveSimulation.Tick(ProxyRailComp.DistanceAlongSpline, ProxyRailComp.EnterSide, DeltaTime, ProxyRailComp.Speed, bReachedEnd, ExitSide);
		
		const FTransform SplineTransform = Rail.Spline.GetWorldTransformAtSplineDistance(ProxyRailComp.DistanceAlongSpline);
		NewLocation += SplineTransform.Rotation.RotateVector(AccOffset.Value);
		AccOffset.AccelerateTo(FVector::ZeroVector, 0.5, DeltaTime);

		MoveData.AddDeltaFromMoveToPositionWithCustomVelocity(NewLocation, SplineTransform.Rotation.ForwardVector * ProxyRailComp.Speed);

		if(bReachedEnd)
			Exit(Rail, ExitSide);

		ProxyMoveComp.ApplyMove(MoveData);

#if !RELEASE
		GetSubframeLog()
			.Value("bReachedEnd", bReachedEnd)
			.Value("ExitSide", ExitSide)
			.Sphere("NewLocation", NewLocation, MagnetDrone::Radius, FLinearColor::Green)
		;
#endif
	}

	private void Exit(const APinballRail Rail, EPinballRailHeadOrTail ExitSide)
	{
		if(ProxyRailComp.Rail.ShouldSyncWhenExiting(ExitSide))
		{
			ProxyRailComp.ExitSide = ExitSide;
			ProxyRailComp.ExitSyncPoint = ProxyRailComp.Rail.GetSyncPoint(ExitSide);
			ProxyRailComp.ExitSyncPointState = EPinballBallRailSyncPointState::Waiting;
		}
		else
		{
			ProxyRailComp.ExitRail(Rail, ExitSide);
		}
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
