struct FPinballMagnetDroneRailExitSyncPointDeactivateParams
{
	bool bFinished = false;
};

class UPinballMagnetDroneRailExitSyncPointCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(Pinball::Tags::Pinball);
	default CapabilityTags.Add(Pinball::Tags::ControlMovement);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 110;	// After RailMovement

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

		// RailMovement decides when we enter the exit sync point
		if(RailComp.ExitSyncPointState != EPinballBallRailSyncPointState::Waiting)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPinballMagnetDroneRailExitSyncPointDeactivateParams& Params) const
	{
		if(RailComp.ExitSyncPointState == EPinballBallRailSyncPointState::FinishedWaiting)
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
		{
			Params.bFinished = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(Pinball::Tags::BlockedWhileInRail, this);
		
		RailComp.ExitSyncPointState = EPinballBallRailSyncPointState::Waiting;

		FVector SyncPointLocation = RailComp.Rail.GetSyncPointLocation(RailComp.ExitSide);
		FVector SyncPointDirection = RailComp.Rail.GetSyncPointDirection(RailComp.ExitSide, EPinballRailEnterOrExit::Exit);

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

		Pinball::Rail::TriggerExitEvent(BallComp, RailComp.Rail, RailComp.ExitSide);
		Pinball::Rail::TriggerEnterSyncPointEvent(BallComp, RailComp.Rail, RailComp.ExitSyncPoint, RailComp.ExitSide);

		RailComp.PredictedExitSyncPointLaunchTime = (Time::GetPlayerCrumbTrailTime(Player) + Pinball::Rail::SyncPointDelay);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPinballMagnetDroneRailExitSyncPointDeactivateParams Params)
	{
		if(Params.bFinished)
		{
			RailComp.ExitSyncPointState = EPinballBallRailSyncPointState::FinishedWaiting;

			if(RailComp.Rail != nullptr)
			{
				const FVector VisualLocation = BallComp.GetVisualLocation();
				const FVector ExitLocation = VisualLocation.VectorPlaneProject(FVector::ForwardVector);
				const FVector ExitVelocity = RailComp.Rail.GetExitVelocity(RailComp.Speed, RailComp.ExitSide).VectorPlaneProject(FVector::ForwardVector);
				
				auto LaunchOffsetComp = UPinballMagnetDroneLaunchedOffsetComponent::Get(Player);
				FPinballLauncherLerpBackSettings LerpBackSettings;
				LerpBackSettings.bLerpBack = true;
				LerpBackSettings.bBaseDurationOnPing = false;
				LaunchOffsetComp.ApplyLaunchedOffset(LerpBackSettings, ExitLocation, ExitVelocity, VisualLocation);

				Player.SetActorVelocity(ExitVelocity);
				
				Pinball::Rail::TriggerLaunchEvent(BallComp, RailComp.Rail, RailComp.ExitSide, EPinballRailEnterOrExit::Exit);
				Pinball::Rail::TriggerExitSyncPointEvent(BallComp, RailComp.Rail, RailComp.ExitSyncPoint, RailComp.ExitSide);
			}
		}
		else
		{
			Pinball::Rail::TriggerExitSyncPointEvent(BallComp, RailComp.Rail, RailComp.ExitSyncPoint, RailComp.ExitSide);
			Pinball::Rail::TriggerExitEvent(BallComp, RailComp.Rail, RailComp.ExitSide);
		}

		Player.UnblockCapabilities(Pinball::Tags::BlockedWhileInRail, this);

		RailComp.Reset(true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData))
			return;

		const FVector SyncPointLocation = RailComp.Rail.GetSyncPointLocation(RailComp.ExitSide);

		AccOffset.AccelerateTo(FVector::ZeroVector, Pinball::Movement::RailInterpToSyncPointDuration, DeltaTime);
		FVector TargetLocation = SyncPointLocation + AccOffset.Value;

		MoveData.AddDeltaFromMoveTo(TargetLocation);

		MoveComp.ApplyMove(MoveData);
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
#if !RELEASE
		const FVector SyncPointLocation = RailComp.Rail.GetSyncPointLocation(RailComp.ExitSide);
		TemporalLog.DirectionalArrow("AccOffset;Value", SyncPointLocation, AccOffset.Value);
		TemporalLog.DirectionalArrow("AccOffset;Velocity", SyncPointLocation + AccOffset.Value, AccOffset.Velocity);
#endif
	}
};