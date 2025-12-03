struct FPinballMagnetDroneRailMovementDeactivateParams
{
	bool bFinished = false;
};

class UPinballMagnetDroneRailMovementCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(Pinball::Tags::Pinball);
	default CapabilityTags.Add(Pinball::Tags::ControlMovement);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	UPinballBallComponent BallComp;
	UPinballMagnetDroneRailComponent RailComp;
	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData MoveData;

	FHazeAcceleratedVector AccOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallComp = UPinballBallComponent::Get(Player);
		RailComp = UPinballMagnetDroneRailComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		MoveData = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!RailComp.IsInAnyRail())
			return false;

		if(RailComp.IsWaitingSyncPoint())
			return false;

		if(RailComp.ExitSyncPointState != EPinballBallRailSyncPointState::NoSyncPoint)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPinballMagnetDroneRailMovementDeactivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(RailComp.ExitSyncPointState != EPinballBallRailSyncPointState::NoSyncPoint)
		{
			Params.bFinished = true;
			return true;
		}

		if(RailComp.Rail != nullptr && RailComp.Rail.IsActorDisabled())
			return true;

		if(!RailComp.IsInAnyRail())
		{
			Params.bFinished = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(RailComp.EnterSyncPoint == nullptr)
		{
			// We have no enter sync point, so this is when we actually enter the rail
			Pinball::Rail::TriggerEnterEvent(BallComp, RailComp.Rail, RailComp.ExitSide);
		}

		RailComp.Speed = RailComp.Rail.GetEnterSpeed(MoveComp.Velocity, RailComp.EnterSide);
		RailComp.DistanceAlongSpline = RailComp.Rail.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);

		Player.BlockCapabilities(Pinball::Tags::PinballMovement, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(Pinball::Tags::BlockedWhileInRail, this);

		const FTransform SplineTransform = RailComp.Rail.Spline.GetClosestSplineWorldTransformToWorldLocation(Player.ActorLocation);
		const FVector RelativeLocation = SplineTransform.InverseTransformPositionNoScale(Player.ActorLocation);
		AccOffset.SnapTo(RelativeLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPinballMagnetDroneRailMovementDeactivateParams Params)
	{
		Player.UnblockCapabilities(Pinball::Tags::PinballMovement, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(Pinball::Tags::BlockedWhileInRail, this);

		if(Params.bFinished)
		{
			if(!RailComp.Rail.ShouldSyncWhenExiting(RailComp.ExitSide))
			{
				const FVector VisualLocation = BallComp.GetVisualLocation();
				const FVector ExitLocation = VisualLocation.VectorPlaneProject(FVector::ForwardVector);
				const FVector ExitVelocity = RailComp.Rail.GetExitVelocity(RailComp.Speed, RailComp.ExitSide).VectorPlaneProject(FVector::ForwardVector);
				
				auto LaunchOffsetComp = UPinballMagnetDroneLaunchedOffsetComponent::Get(Player);
				FPinballLauncherLerpBackSettings LerpBackSettings;
				LerpBackSettings.bLerpBack = true;
				LerpBackSettings.bBaseDurationOnPing = false;
				LaunchOffsetComp.ApplyLaunchedOffset(LerpBackSettings, ExitLocation, ExitVelocity, VisualLocation);

				// We actually exited the rail, with no sync point
				Player.SetActorVelocity(ExitVelocity);
				
				Pinball::Rail::TriggerExitEvent(BallComp, RailComp.Rail, RailComp.ExitSide);
				
				RailComp.Reset(true);
			}
		}
		else
		{
			Pinball::Rail::TriggerExitEvent(BallComp, RailComp.Rail, RailComp.ExitSide);
			RailComp.Reset(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		if(!MoveComp.PrepareMove(MoveData))
			return;

		const APinballRail Rail = RailComp.Rail;
		const FTransform SplineTransform = Rail.Spline.GetWorldTransformAtSplineDistance(RailComp.DistanceAlongSpline);

		FPinballRailMoveSimulation MoveSimulation;
		MoveSimulation.Initialize(Rail);

		bool bShouldExit = false;
		EPinballRailHeadOrTail ExitSide = EPinballRailHeadOrTail::None;
		FVector NewLocation = MoveSimulation.Tick(RailComp.DistanceAlongSpline, RailComp.EnterSide, DeltaTime, RailComp.Speed, bShouldExit, ExitSide);

		NewLocation += SplineTransform.Rotation.RotateVector(AccOffset.Value);
		AccOffset.AccelerateTo(FVector::ZeroVector, 0.5, DeltaTime);

		MoveData.AddDeltaFromMoveTo(NewLocation);

		if(bShouldExit)
			Exit(Rail, ExitSide);

		MoveComp.ApplyMove(MoveData);
	}

	private void Exit(const APinballRail Rail, EPinballRailHeadOrTail ExitSide)
	{
		if(RailComp.Rail.ShouldSyncWhenExiting(ExitSide))
		{
			RailComp.ExitSide = ExitSide;
			RailComp.ExitSyncPoint = RailComp.Rail.GetSyncPoint(ExitSide);
			RailComp.ExitSyncPointState = EPinballBallRailSyncPointState::Waiting;
		}
		else
		{
			RailComp.ExitRail(Rail, ExitSide, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
#if !RELEASE
		TemporalLog.Value("DistanceAlongSpline", RailComp.DistanceAlongSpline);
		TemporalLog.Sphere("Actor Location", Player.ActorLocation, BallComp.GetRadius(), FLinearColor::LucBlue);

		const FTransform SplineTransform = RailComp.Rail.Spline.GetWorldTransformAtSplineDistance(RailComp.DistanceAlongSpline);
		TemporalLog.Sphere("Spline Location", SplineTransform.Location, BallComp.GetRadius(), FLinearColor::Red);
		TemporalLog.DirectionalArrow("Acc Offset", SplineTransform.Location, AccOffset.Value);
#endif
	}
};