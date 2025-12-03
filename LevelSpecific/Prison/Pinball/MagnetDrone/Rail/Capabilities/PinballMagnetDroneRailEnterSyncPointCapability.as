struct FPinballMagnetDroneRailEnterSyncPointDeactivateParams
{
	bool bFinished = false;
};

class UPinballMagnetDroneRailEnterSyncPointCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(Pinball::Tags::Pinball);
	default CapabilityTags.Add(Pinball::Tags::ControlMovement);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 90; // Before RailMovement

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

		if (MoveComp.HasMovedThisFrame())
			return false;

		// Only when in a rail
		if (!RailComp.IsInAnyRail())
			return false;

		if (!RailComp.Rail.ShouldSyncWhenEntering(RailComp.EnterSide))
			return false;

		// We have already synced at the enter sync point
		if (RailComp.EnterSyncPointState == EPinballBallRailSyncPointState::FinishedWaiting)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPinballMagnetDroneRailEnterSyncPointDeactivateParams& Params) const
	{
		if(RailComp.EnterSyncPointState == EPinballBallRailSyncPointState::FinishedWaiting)
		{
			Params.bFinished = true;
			return true;
		}

		if(ActiveDuration > Pinball::Rail::SyncPointDelay)
		{
			Params.bFinished = true;
			return true;
		}

		if(RailComp.Rail != nullptr && RailComp.Rail.IsActorDisabled())
			return true;

		if (!RailComp.IsInAnyRail())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(Pinball::Tags::BlockedWhileInRail, this);

		RailComp.EnterSyncPointState = EPinballBallRailSyncPointState::Waiting;

		FVector SyncPointLocation = RailComp.Rail.GetSyncPointLocation(RailComp.EnterSide);
		FVector SyncPointDirection = RailComp.Rail.GetSyncPointDirection(RailComp.EnterSide, EPinballRailEnterOrExit::Enter);

		FVector CurrentLocation = Owner.ActorLocation;
		FVector CurrentVelocity = Owner.ActorVelocity;
		if(CurrentLocation.IsAbovePlane(FPlane(SyncPointLocation, SyncPointDirection)))
		{
			CurrentLocation = CurrentLocation.PointPlaneProject(SyncPointLocation, SyncPointDirection);
			CurrentVelocity = CurrentVelocity.VectorPlaneProject(SyncPointDirection);
		}

		if(CurrentVelocity.DotProduct(SyncPointLocation - CurrentLocation) < 0)
			CurrentVelocity = FVector::ZeroVector;

		FVector Offset = CurrentLocation - SyncPointLocation;
		AccOffset.SnapTo(Offset, CurrentVelocity);

		Pinball::Rail::TriggerEnterEvent(BallComp, RailComp.Rail, RailComp.ExitSide);
		Pinball::Rail::TriggerEnterSyncPointEvent(BallComp, RailComp.Rail, RailComp.EnterSyncPoint, RailComp.EnterSide);

		RailComp.PredictedEnterSyncPointLaunchTime = (Time::GetPlayerCrumbTrailTime(Player) + Pinball::Rail::SyncPointDelay);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPinballMagnetDroneRailEnterSyncPointDeactivateParams Params)
	{
		if(Params.bFinished)
		{
			if(RailComp.Rail != nullptr)
			{
				RailComp.EnterSyncPointState = EPinballBallRailSyncPointState::FinishedWaiting;
				RailComp.Speed = RailComp.Rail.GetEnterSpeed(MoveComp.Velocity, RailComp.EnterSide);

				Pinball::Rail::TriggerLaunchEvent(BallComp, RailComp.Rail, RailComp.EnterSide, EPinballRailEnterOrExit::Enter);
				Pinball::Rail::TriggerExitSyncPointEvent(BallComp, RailComp.Rail, RailComp.EnterSyncPoint, RailComp.EnterSide);
			}

			RailComp.PredictedEnterSyncPointLaunchTime = -1;
		}
		else
		{
			Pinball::Rail::TriggerExitSyncPointEvent(BallComp, RailComp.Rail, RailComp.EnterSyncPoint, RailComp.EnterSide);
			Pinball::Rail::TriggerExitEvent(BallComp, RailComp.Rail, RailComp.ExitSide);
			RailComp.Reset(false);
		}

		Player.UnblockCapabilities(Pinball::Tags::BlockedWhileInRail, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData))
			return;

		const FVector SyncPointLocation = RailComp.Rail.GetSyncPointLocation(RailComp.EnterSide);

		AccOffset.AccelerateTo(FVector::ZeroVector, Pinball::Movement::RailInterpToSyncPointDuration, DeltaTime);
		FVector TargetLocation = SyncPointLocation + AccOffset.Value;

		MoveData.AddDeltaFromMoveTo(TargetLocation);

		MoveComp.ApplyMove(MoveData);
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
#if !RELEASE
		FVector SyncPointLocation = RailComp.Rail.GetSyncPointLocation(RailComp.EnterSide);
		TemporalLog.DirectionalArrow("AccOffset;Value", SyncPointLocation, AccOffset.Value);
		TemporalLog.DirectionalArrow("AccOffset;Velocity", SyncPointLocation + AccOffset.Value, AccOffset.Velocity);
#endif
	}
};