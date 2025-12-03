const FStatID STAT_PinballPredictionComponent_ApplyPrediction(n"PinballPredictionComponent_ApplyPrediction");
const FStatID STAT_PinballPredictionComponent_InterpolateToPrediction(n"PinballPredictionComponent_InterpolateToPrediction");
const FStatID STAT_PinballPredictionComponent_TemporalLogFinalState(n"PinballPredictionComponent_TemporalLogFinalState");

UCLASS(NotBlueprintable, NotPlaceable)
class UPinballMagnetDronePredictionComponent : UPinballPredictionComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = true;

	private AHazePlayerCharacter Player;
	private UPinballMagnetDroneLaunchedComponent LaunchedComp;
	private UPinballMagnetDroneRailComponent RailComp;
	private UPinballPredictionSyncComponent SyncComp;
	private UPinballMovementSettings MovementSettings;

	// Predicted
	APinballMagnetDroneProxy Proxy;
	private FVector MispredictionCorrectionVelocity;

	float PredictionStartTime;
	float PredictionDuration;

	/**
	 * Ball Side (Zoe)
	 */
	private float MovementInputHeldDuration = -1.0;
	private float HeldMovementInput = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if(!Network::IsGameNetworked())
			return;

		Player = Cast<AHazePlayerCharacter>(Owner);

		LaunchedComp = UPinballMagnetDroneLaunchedComponent::Get(Player);
		RailComp = UPinballMagnetDroneRailComponent::Get(Player);

		SyncComp = UPinballPredictionSyncComponent::GetOrCreate(Player, n"PredictionSyncComp");

		auto RespawnComp = UPlayerRespawnComponent::Get(Player);
		RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnRespawned");

		if(HasControl())
			return;

		auto TeleportComp = UTeleportResponseComponent::GetOrCreate(Player);
		TeleportComp.OnTeleported.AddUFunction(this, n"OnTeleported");

		MovementSettings = UPinballMovementSettings::GetSettings(Player);

		Proxy = SpawnActor(APinballMagnetDroneProxy, Player.ActorLocation, Player.ActorRotation, bDeferredSpawn = true);
		Proxy.RepresentedActor = Player;
		FinishSpawningActor(Proxy);

#if !RELEASE
		TEMPORAL_LOG(this, Owner, "PinballMagnetDronePrediction");
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!Network::IsGameNetworked())
		{
			SetComponentTickEnabled(false);
			return;
		}

		if(HasControl())
		{
			SyncAdditionalInformation();
		}
		else
		{
			UpdateMovementInputHeldDuration(DeltaSeconds);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		Super::OnActorEnabled();
		
		if(Proxy != nullptr)
			Proxy.RemoveActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		Super::OnActorDisabled();
		
		if(Proxy != nullptr)
			Proxy.AddActorDisable(this);
	}

	bool UpdateLatestAvailableActorPosition() override
	{
		if(!Super::UpdateLatestAvailableActorPosition())
			return false;

		check(LatestActorPosition.RelativeType == EHazeActorPositionRelativeType::WorldLocation || LatestActorPosition.RelativeComponent != nullptr);

		const FPinballPredictionSyncedData SyncedData = GetLatestSyncedData();

		if(SyncedData.RailData.EnterSyncPointState == EPinballBallRailSyncPointState::Waiting)
		{
			ModifyLatestAvailablePinballData_EnterSyncPoint(LatestActorPosition, LatestCrumbTime, SyncedData.RailData);
		}
		else if(SyncedData.RailData.IsEnterSyncPointLaunching(LatestCrumbTime))
		{
			ModifyLatestAvailablePinballData_EnterSyncPointLaunch(LatestActorPosition, LatestCrumbTime, SyncedData.RailData);
		}
		else if(SyncedData.RailData.ExitSyncPointState == EPinballBallRailSyncPointState::Waiting)
		{
			ModifyLatestAvailablePinballData_ExitSyncPoint(LatestActorPosition, LatestCrumbTime, SyncedData.RailData);
		}
		else if(SyncedData.RailData.IsExitSyncPointLaunching(LatestCrumbTime))
		{
			ModifyLatestAvailablePinballData_ExitSyncPointLaunch(LatestActorPosition, LatestCrumbTime, SyncedData.RailData);
		}
		else if (LaunchedComp.LaunchedPredictedOtherSideTime > 0.0)
		{
			ModifyLatestAvailablePinballData_Launch(LatestActorPosition, LatestCrumbTime);
		}
		
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this, "UpdateLatestAvailableActorPosition");
		TemporalLog.Struct("ActorPosition;", LatestActorPosition);
		TemporalLog.Value("CrumbTime", LatestCrumbTime);
		TemporalLog.Transform("WorldTransform", FTransform(LatestActorPosition.WorldRotation, LatestActorPosition.WorldLocation));
		TemporalLog.DirectionalArrow("WorldVelocity", LatestActorPosition.WorldLocation, LatestActorPosition.WorldVelocity);
#endif

		return true;
	}

	void Init(uint InFrameNumber, float InPredictionLoopStartTime, float InPredictionLoopEndTime) override
	{
		FHazeSyncedActorPosition ActorPosition;
		float CrumbTime = 0.0;
		TryGetLatestAvailableActorPosition(ActorPosition, CrumbTime);

		PredictionDuration = GetPredictionDuration();
		PredictionStartTime = InPredictionLoopEndTime - PredictionDuration;

		FPinballPredictionSyncedData SyncedData = GetLatestSyncedData();

		Proxy.Initialize(
			ActorPosition,
			SyncedData,
			CrumbTime,
			PredictionDuration,
			ActorPosition.MovementInput.Y,
			ActorPosition.MovementInput.Z,
			MovementInputHeldDuration
		);

		Proxy.PredictedPath.CorrectionVelocity = MispredictionCorrectionVelocity;
	
		// SubframeNumber should be reset in Proxy.Initialize()
		check(Proxy.SubframeNumber == 0);

#if EDITOR
		Proxy.MoveComp.DebugMovementSweeps.Reset();
#endif
	}

	bool SubTick(uint InFrameNumber, uint InSubframeNumber, float InPredictionTime, float InDeltaTime) override
	{
		if(!bHasEverReceivedAnyData)
			return false;

		float PredictionTickEndTime = InPredictionTime + InDeltaTime;
		if(PredictionTickEndTime < PredictionStartTime)
		{
			// Our prediction has not started yet
			return false;
		}

		// Shorter first tick if needed
		const float DeltaTime = Math::Min(InDeltaTime, (InPredictionTime + InDeltaTime) - PredictionStartTime);

		Proxy.PerformTick(InSubframeNumber, InPredictionTime, DeltaTime);
		return Super::SubTick(InFrameNumber, InSubframeNumber, InPredictionTime, InDeltaTime);
	}

	void Finalize() override
	{
		Proxy.Finalize(PredictionDuration);

		InterpolateToPrediction(Proxy.PredictedPath, Time::GetActorDeltaSeconds(Player));
		MispredictionCorrectionVelocity = Proxy.PredictedPath.CorrectionVelocity;

#if !RELEASE
		TemporalLogFinalState();
#endif
	}

	private void UpdateMovementInputHeldDuration(float DeltaTime)
	{
		if (HasControl())
			return;

		FHazeSyncedActorPosition ActorPosition;
		float CrumbTime = 0.0;
		if(!TryGetLatestAvailableActorPosition(ActorPosition, CrumbTime))
		{
			MovementInputHeldDuration = 0.0;
			HeldMovementInput = 0;
			return;
		}

		const float Input = ActorPosition.MovementInput.Y;
		if (Math::Abs(Input) < 0.05)
		{
			MovementInputHeldDuration = -1.0;
			HeldMovementInput = Input;
		}
		else if (MovementInputHeldDuration >= 0.0)
		{
			if (Math::Sign(Input) != Math::Sign(HeldMovementInput))
			{
				MovementInputHeldDuration = 0.0;
				HeldMovementInput = Input;
			}
			else
			{
				MovementInputHeldDuration += DeltaTime;
				HeldMovementInput = Input;
			}
		}
		else
		{
			MovementInputHeldDuration = 0.0;
			HeldMovementInput = Input;
		}
	}

	private void SyncAdditionalInformation() const
	{
		check(HasControl());

		FPinballPredictionSyncedData SyncedData;
		SyncedData.MovementData = FPinballPredictionSyncedMovementData(Player);
		SyncedData.LaunchedData = FPinballPredictionSyncedLaunchedData(LaunchedComp);
		SyncedData.RailData = FPinballPredictionSyncedRailData(RailComp);
		SyncedData.AttractionData = FPinballPredictionSyncedAttractionData(Player);
		SyncedData.AttachedData = FPinballPredictionSyncedAttachedData(Player);

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this, "Synced Data");
		SyncedData.LogToTemporalLog(TemporalLog, HasControl(), Time::ThisSideCrumbTrailSendTime);
#endif

		SyncComp.SetCrumbValueStruct(SyncedData);
	}

	private void ModifyLatestAvailablePinballData_Launch(
		FHazeSyncedActorPosition&out ActorPosition,
		float& CrumbTime) const
	{
		const float HalfPing = Network::PingOneWaySeconds * Time::WorldTimeDilation;
		const float OtherSideTime = Time::OtherSideCrumbTrailSendTimePrediction;

		if(LaunchedComp.LaunchData.bFromBallSide)
		{
			// If we have a simulated launch, we return the launch data instead of control data
			if (LaunchedComp.LaunchedPredictedOtherSideTime > 0)
			{
				if (CrumbTime > LaunchedComp.LaunchedPredictedOtherSideTime)
				{
				}
				else
				{
					// Lock the "synced" position to the launch location, so that we predict from these
					ActorPosition.RelativeType = EHazeActorPositionRelativeType::WorldLocation;
					ActorPosition.RelativeComponent = nullptr;
					ActorPosition.RelativeLocation = LaunchedComp.LaunchData.LaunchLocation;
					ActorPosition.RelativeVelocity = LaunchedComp.LaunchData.LaunchVelocity;
					ActorPosition.WorldLocation = LaunchedComp.LaunchData.LaunchLocation;
					ActorPosition.WorldVelocity = LaunchedComp.LaunchData.LaunchVelocity;

					CrumbTime = LaunchedComp.LaunchedPredictedOtherSideTime;
				}
			}
		}
		else
		{
			// If we have a simulated launch, we return the launch data instead of control data
			if (LaunchedComp.LaunchedPredictedOtherSideTime > 0)
			{
				const float ElapsedTime = (OtherSideTime - LaunchedComp.LaunchedPredictedOtherSideTime);
				float PredictTimeToBlendAway = Math::Max(HalfPing + LaunchedComp.PredictedLaunchAheadTime, 0);

				if (CrumbTime > LaunchedComp.LaunchedPredictedOtherSideTime)
				{
					// Use the data from the other side that was after we launched.
					// Our prediction is still "ahead" of where it wants to be, so slowly put
					// the data back into place
					if (PredictTimeToBlendAway > 0)
					{
						CrumbTime -= Math::GetMappedRangeValueClamped(
							FVector2D(0.0, PredictTimeToBlendAway + Pinball::Prediction::LaunchPredictionSlowdownTime),
							FVector2D(PredictTimeToBlendAway, 0.0),
							ElapsedTime,
						);
					}
				}
				else
				{
					// Lock the "synced" position to the launch location, so that we predict from these
					ActorPosition.RelativeType = EHazeActorPositionRelativeType::WorldLocation;
					ActorPosition.RelativeComponent = nullptr;
					ActorPosition.RelativeLocation = LaunchedComp.LaunchData.LaunchLocation;
					ActorPosition.RelativeVelocity = LaunchedComp.LaunchData.LaunchVelocity;
					ActorPosition.WorldLocation = LaunchedComp.LaunchData.LaunchLocation;
					ActorPosition.WorldVelocity = LaunchedComp.LaunchData.LaunchVelocity;

					CrumbTime = LaunchedComp.LaunchedPredictedOtherSideTime;

					// Go back one frame in time so that the first frame will not be 0 delta time, meaning we stand still for one frame
					CrumbTime -= LaunchedComp.PredictedLaunchAheadTime;

					CrumbTime += Math::GetMappedRangeValueClamped(
						FVector2D(0.0, HalfPing + LaunchedComp.PredictedLaunchAheadTime + Pinball::Prediction::LaunchPredictionSlowdownTime),
						FVector2D(0.0, HalfPing + LaunchedComp.PredictedLaunchAheadTime),
						ElapsedTime,
					);
				}
			}
		}
	}

	private void ModifyLatestAvailablePinballData_EnterSyncPoint(
		FHazeSyncedActorPosition&out ActorPosition,
		float& CrumbTime,
		FPinballPredictionSyncedRailData RailData) const
	{
		// While in an Enter SyncPoint, lock ourselves to that sync point.
		APinballRail Rail = nullptr;
		EPinballRailHeadOrTail EnterSide = EPinballRailHeadOrTail::None;
		if(RailData.Rail != nullptr)
		{
			Rail = RailData.Rail;
			EnterSide = RailData.EnterSide;
		}
		else if(Proxy.RailComp.Rail != nullptr)
		{
			Rail = Proxy.RailComp.Rail;
			EnterSide = Proxy.RailComp.EnterSide;
		}
		else
		{
			check(false);
		}

		const FVector EnterLocation = Rail.GetSyncPointLocation(EnterSide);

		ActorPosition.RelativeType = EHazeActorPositionRelativeType::WorldLocation;
		ActorPosition.RelativeComponent = nullptr;
		ActorPosition.RelativeLocation = EnterLocation;
		ActorPosition.RelativeVelocity = FVector::ZeroVector;
		ActorPosition.WorldLocation = EnterLocation;
		ActorPosition.WorldVelocity = FVector::ZeroVector;
	}

	private void ModifyLatestAvailablePinballData_EnterSyncPointLaunch(
		FHazeSyncedActorPosition&out ActorPosition,
		float& CrumbTime,
		FPinballPredictionSyncedRailData RailData) const
	{
		// While in an Enter SyncPoint, lock ourselves to that sync point.
		APinballRail Rail = nullptr;
		EPinballRailHeadOrTail EnterSide = EPinballRailHeadOrTail::None;
		if(RailData.Rail != nullptr)
		{
			Rail = RailData.Rail;
			EnterSide = RailData.EnterSide;
		}
		else if(Proxy.RailComp.Rail != nullptr)
		{
			Rail = Proxy.RailComp.Rail;
			EnterSide = Proxy.RailComp.EnterSide;
		}
		else
		{
			check(false);
		}

		const FVector EnterLocation = Rail.GetSyncPointLocation(EnterSide);

		ActorPosition.RelativeType = EHazeActorPositionRelativeType::WorldLocation;
		ActorPosition.RelativeComponent = nullptr;
		ActorPosition.RelativeLocation = EnterLocation;
		ActorPosition.RelativeVelocity = FVector::ZeroVector;
		ActorPosition.WorldLocation = EnterLocation;
		ActorPosition.WorldVelocity = FVector::ZeroVector;

		// Place the crumb trail at the launch time to predict from there
		CrumbTime = RailData.PredictedEnterSyncPointLaunchTime;
	}

	private void ModifyLatestAvailablePinballData_ExitSyncPoint(
		FHazeSyncedActorPosition&out ActorPosition,
		float& CrumbTime,
		FPinballPredictionSyncedRailData RailData) const
	{
		// While in an Exit SyncPoint, lock ourselves to that sync point.
		APinballRail Rail = nullptr;
		EPinballRailHeadOrTail ExitSide = EPinballRailHeadOrTail::None;
		if(RailData.Rail != nullptr)
		{
			Rail = RailData.Rail;
			ExitSide = RailData.ExitSide;
		}
		else if(Proxy.RailComp.Rail != nullptr)
		{
			Rail = Proxy.RailComp.Rail;
			ExitSide = Proxy.RailComp.ExitSide;
		}
		else
		{
			check(false);
		}

		const FVector ExitLocation = Rail.GetSyncPointLocation(ExitSide);

		ActorPosition.RelativeType = EHazeActorPositionRelativeType::WorldLocation;
		ActorPosition.RelativeComponent = nullptr;
		ActorPosition.RelativeLocation = ExitLocation;
		ActorPosition.RelativeVelocity = FVector::ZeroVector;
		ActorPosition.WorldLocation = ExitLocation;
		ActorPosition.WorldVelocity = FVector::ZeroVector;
	}

	private void ModifyLatestAvailablePinballData_ExitSyncPointLaunch(
		FHazeSyncedActorPosition&out ActorPosition,
		float& CrumbTime,
		FPinballPredictionSyncedRailData RailData) const
	{
		// While in an Enter Exit, lock ourselves to that sync point, and set the exit velocity
		APinballRail Rail = nullptr;
		EPinballRailHeadOrTail ExitSide = EPinballRailHeadOrTail::None;
		if(RailData.Rail != nullptr)
		{
			Rail = RailData.Rail;
			ExitSide = RailData.ExitSide;
		}
		else if(Proxy.RailComp.Rail != nullptr)
		{
			Rail = Proxy.RailComp.Rail;
			ExitSide = Proxy.RailComp.ExitSide;
		}
		else
		{
			check(false);
		}

		const FVector ExitLocation = Rail.GetSyncPointLocation(ExitSide);
		const FVector ExitVelocity = Rail.GetExitVelocity(0, ExitSide);

		ActorPosition.RelativeType = EHazeActorPositionRelativeType::WorldLocation;
		ActorPosition.RelativeComponent = nullptr;
		ActorPosition.RelativeLocation = ExitLocation;
		ActorPosition.RelativeVelocity = ExitVelocity;
		ActorPosition.WorldLocation = ExitLocation;
		ActorPosition.WorldVelocity = ExitVelocity;

		// Place the crumb trail at the launch time to predict from there
		CrumbTime = RailData.PredictedExitSyncPointLaunchTime;
	}

	FPinballPredictionSyncedData GetLatestSyncedData(bool bAllowPredictionToModify = true) const
	{
		float CrumbTime = 0;
		FPinballPredictionSyncedData SyncedData;
		SyncComp.GetLatestAvailableData(SyncedData, CrumbTime);

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this, "GetLatestSyncedData");
		SyncedData.LogToTemporalLog(TemporalLog, HasControl(), CrumbTime);
#endif

		if(!SyncComp.HasUsableDataInCrumbTrail())
		{
			// Don't allow modification if we don't have any synced data yet
#if !RELEASE
			TemporalLog.Status("No usable data in crumb trail!", FLinearColor::Yellow);
#endif
			return SyncedData;
		}

		if(bAllowPredictionToModify)
		{
			if(LaunchedComp.LaunchedPredictedOtherSideTime > 0 && LaunchedComp.LaunchedPredictedOtherSideTime > CrumbTime - 0.15)
			{
				ModifyLatestSyncedData_Launch(SyncedData);
			}
			else if(SyncedData.RailData.IsEnterSyncPointLaunching(LatestCrumbTime))
			{
				ModifyLatestSyncedData_EnterSyncPointLaunch(SyncedData);
			}
			else if(SyncedData.RailData.IsExitSyncPointLaunching(LatestCrumbTime))
			{
				ModifyLatestSyncedData_ExitSyncPointLaunch(SyncedData);
			}
		}

		return SyncedData;
	}

	private void ModifyLatestSyncedData_Launch(FPinballPredictionSyncedData& SyncedData) const
	{
		// No ground contact during launch
		SyncedData.MovementData.GroundContact = FHitResult();
	}

	private void ModifyLatestSyncedData_EnterSyncPointLaunch(FPinballPredictionSyncedData& SyncedData) const
	{
		SyncedData.RailData.DistanceAlongSpline = 0;
		SyncedData.RailData.Speed = float32(SyncedData.RailData.Rail.GetEnterSpeed(FVector::ZeroVector, SyncedData.RailData.EnterSide));
		SyncedData.RailData.EnterSyncPointState = EPinballBallRailSyncPointState::FinishedWaiting;
	}

	private void ModifyLatestSyncedData_ExitSyncPointLaunch(FPinballPredictionSyncedData& SyncedData) const
	{
		SyncedData.RailData.ExitSyncPointState = EPinballBallRailSyncPointState::FinishedWaiting;
	}

	FPinballPredictedPath GetPredictedPath() const
	{
		return Proxy.PredictedPath;
	}

	private void InterpolateToPrediction(FPinballPredictedPath& PredictedPath, float DeltaTime) const
	{
		FScopeCycleCounter CycleCounter(STAT_PinballPredictionComponent_InterpolateToPrediction);

		FVector CurrentLocation = Player.ActorLocation;

		const float OptimalTime = GetPredictionDuration();
		const FVector PredictOptimalLocation = PredictedPath.GetLocationAtTime(OptimalTime);

		float ClosestSplineTime = PredictedPath.GetTimeClosestToLocation(CurrentLocation);
		FVector ClosestSplineLocation = PredictedPath.GetLocationAtTime(ClosestSplineTime);
		float DistanceToClosestSplineLocation = ClosestSplineLocation.Distance(CurrentLocation);

		// Decay our offset away from the spline
		FVector MaintainedOffset = (CurrentLocation - ClosestSplineLocation);
		if (Pinball::Prediction::bUseAcceleratedMispredictionCorrection)
		{
			FVector OffsetDirection = MaintainedOffset.GetSafeNormal();
			float OffsetDistance = MaintainedOffset.Size();

			float PrevCorrectionSpeed = PredictedPath.CorrectionVelocity.DotProduct(-OffsetDirection);
			float NewCorrectionSpeed = Math::Min(
				PrevCorrectionSpeed + Pinball::Prediction::MispredictionCorrectionAcceleration * DeltaTime,
				OffsetDistance / DeltaTime
			);

			OffsetDistance -= (NewCorrectionSpeed + PrevCorrectionSpeed) * 0.5 * DeltaTime;
			OffsetDistance = Math::Max(0, OffsetDistance);
			MaintainedOffset = OffsetDirection * OffsetDistance;

			PredictedPath.CorrectionVelocity = -OffsetDirection * NewCorrectionSpeed;
		}
		else
		{
			FVector NewOffset = MaintainedOffset * Math::Pow(Pinball::Prediction::MispredictionOffsetDecay, DeltaTime);
			PredictedPath.CorrectionVelocity = (NewOffset - MaintainedOffset) / DeltaTime;
			MaintainedOffset = NewOffset;
		}

		float SplineTargetTimeLength = (OptimalTime - ClosestSplineTime);

		const bool bIsVeryFarAway = DistanceToClosestSplineLocation > Pinball::Prediction::TimeBasedTeleportThreshold;
		FVector SplinePredictedLocation;
		float AnchorTime = -1.0;
		if (!bIsVeryFarAway)
		{
			// Advance on the spline with faster speed, dependent on how behind we are
			AnchorTime = ClosestSplineTime + DeltaTime + Math::Max(
				(SplineTargetTimeLength - DeltaTime) * DeltaTime * Pinball::Prediction::TimeBasedCatchUpSpeed,
				DeltaTime * Pinball::Prediction::TimeBasedCatchUpMinimumBoost);

			// We don't want to advance past the optimal time
			AnchorTime = Math::Min(AnchorTime, OptimalTime);

			SplinePredictedLocation = PredictedPath.GetLocationAtTime(AnchorTime);
			SplinePredictedLocation += MaintainedOffset;
		}
		else
		{
			SplinePredictedLocation = PredictedPath.GetLocationAtTime(OptimalTime);
		}

#if !RELEASE
		TEMPORAL_LOG(this).Page("Interpolation")
			.Sphere(f"Current Location", CurrentLocation, MagnetDrone::Radius)
			.DirectionalArrow(f"Current Velocity", CurrentLocation, Player.ActorVelocity)
			.Value(f"Closest Spline Time", ClosestSplineTime)
			.Value(f"Optimal Time", OptimalTime)
			.Value(f"Anchor Time", AnchorTime)
			.Value(f"Spline Target Time Length", SplineTargetTimeLength)
			.Value(f"Spline Total Time", PredictedPath.GetTotalTime())
			.Sphere(f"Predict Optimal Location", PredictOptimalLocation, MagnetDrone::Radius, FLinearColor::Red)
			.Sphere(f"Closest Spline Location", ClosestSplineLocation, MagnetDrone::Radius, FLinearColor::DPink)
			.Value(f"Distance To Closest Spline Location", DistanceToClosestSplineLocation)
			.Sphere(f"Spline Predicted Location", SplinePredictedLocation, MagnetDrone::Radius, FLinearColor::Purple)
			.Arrow(f"Offset From Optimal", PredictedPath.GetLocationAtTime(AnchorTime), PredictOptimalLocation)
			.DirectionalArrow(f"Maintained Offset", PredictedPath.GetLocationAtTime(AnchorTime), MaintainedOffset)
			.DirectionalArrow(f"Correction Velocity", CurrentLocation, PredictedPath.CorrectionVelocity)
		;
#endif

		PredictedPath.InterpolatedLocation = SplinePredictedLocation;
	}

	UFUNCTION()
	private void OnTeleported()
	{
		Proxy.PredictedPath.Invalidate();

		// When we are teleported, update our latest crumb position to the local position
		SyncedPositionComp.GetLatestAvailableData(LatestActorPosition, LatestCrumbTime);

		// Fill with static local data
		FillLatestActorPositionWithLocal();
	}

	UFUNCTION()
	private void OnRespawned(AHazePlayerCharacter RespawnedPlayer)
	{
		MispredictionCorrectionVelocity = FVector::ZeroVector;
		SyncedPositionComp.TransitionSync(FInstigator(this, n"Respawn"));
		FillLatestActorPositionWithLocal();
		
		if(Proxy != nullptr)
			Proxy.PredictedPath.Invalidate();
	}

	FVector GetInterpolatedPredictedLocation()
	{
		return GetPredictedPath().InterpolatedLocation;
	}

#if EDITOR
	FVector GetOtherSideLocation() const
	{
		AActor OtherSideActor = Cast<AActor>(Debug::GetPIENetworkOtherSideForDebugging(Owner));
		return OtherSideActor.ActorLocation;
	}
#endif

#if !RELEASE
	void TemporalLogFinalState()
	{
		FScopeCycleCounter CycleCounter(STAT_PinballPredictionComponent_TemporalLogFinalState);

		FHazeSyncedActorPosition ActorPosition;
		float CrumbTime = 0;
		TryGetLatestAvailableActorPosition(ActorPosition, CrumbTime);

		auto PredictedPath = GetPredictedPath();

		TEMPORAL_LOG(this).Page("Launch")
			.Sphere(f"Launch Location", LaunchedComp.LaunchData.LaunchLocation, MagnetDrone::Radius, FLinearColor::Yellow)
			.Value(f"Launch Predicted Time", LaunchedComp.LaunchedPredictedOtherSideTime)
		;

		TEMPORAL_LOG(this).Page("Paddle")
			.DirectionalArrow(f"Velocity", Player.ActorLocation, Player.ActorVelocity)
			.Sphere(f"Latest Location", ActorPosition.WorldLocation, MagnetDrone::Radius)
			.DirectionalArrow(f"Latest Velocity", ActorPosition.WorldLocation, ActorPosition.WorldVelocity)
			.Value(f"Latest Crumb Time", CrumbTime)
		;

		TEMPORAL_LOG(this).Page("Launch")
			.Value(f"Is Launched", LaunchedComp.bIsLaunched)
		;

		PredictedPath.SetTension(1.0);

		FHazeSyncedActorPosition UnmodifiedActorPosition;
		float UnmodifiedCrumbTime = 0;
		SyncedPositionComp.GetLatestAvailableData(UnmodifiedActorPosition, UnmodifiedCrumbTime);

		TEMPORAL_LOG(this).Page("Final")
			.RuntimeSpline(f"Predicted Path Spline", PredictedPath.GetSpline())

			.Sphere(f"Extrapolated Location", PredictedPath.GetExtrapolatedLocation(), 40, FLinearColor::Yellow, 3)
			.Sphere(f"Interpolated Location", PredictedPath.InterpolatedLocation, 40, FLinearColor::White, 3)

			.Sphere(f"Latest Data Location", ActorPosition.WorldLocation, 40, FLinearColor::Green, 3)
			.Sphere(f"Crumb Synced Location", SyncedPositionComp.GetPosition().WorldLocation, 40, FLinearColor::Yellow, 3)
			.Value(f"Crumb Synced Input", SyncedPositionComp.GetPosition().MovementInput.Y)
			.Value(f"Input Held Duration", MovementInputHeldDuration)
			
			.Sphere(f"Actor Location", Player.ActorLocation, 40, FLinearColor::Red, 3)

#if EDITOR
			.Sphere(f"Other Side Location", GetOtherSideLocation(), 40, FLinearColor::LucBlue, 3)
#endif

			.Sphere(f"Unmodified Latest Data Location", UnmodifiedActorPosition.WorldLocation, 40, FLinearColor::Green, 3)
			.Value(f"Unmodified Latest Crumb Time", UnmodifiedCrumbTime)

#if EDITOR
			.Value(f"Interpolated Error", GetOtherSideLocation() - Player.ActorLocation)
#endif
			.Value(f"PredictionDuration", PredictionDuration)
		;
	}
#endif
};