const FStatID STAT_PinballBossBallPredictionComponent_PostInit(n"PinballBossBallPredictionComponent_PostInit");
const FStatID STAT_PinballBossBallPredictionComponent_PostSubTick(n"PinballBossBallPredictionComponent_PostSubTick");
const FStatID STAT_PinballBossBallPredictionComponent_PostFinalize(n"PinballBossBallPredictionComponent_PostFinalize");
const FStatID STAT_PinballBossBallPredictionComponent_InterpolateToPrediction(n"PinballBossBallPredictionComponent_InterpolateToPrediction");
const FStatID STAT_PinballBossBallPredictionComponent_TemporalLogFinalState(n"PinballBossBallPredictionComponent_TemporalLogFinalState");

UCLASS(NotBlueprintable)
class UPinballBossBallPredictionComponent : UPinballPredictionComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = true;

	//access NetSyncedLaunched = private, UPinballBallLaunchedCapability, UPinballSimulationLaunchCapability;
	//access NetSyncedPredictedRail = private, UPinballRailMovementCapability, UPinballSimulationRailCapability;

	private APinballBossBall BossBall;
	private UPinballBossBallLaunchedComponent LaunchedComp;
	private UPinballBossBallSyncComponent SyncComp;
	private UPinballMovementSettings MovementSettings;

	// Predicted
	APinballBossBallProxy Proxy;
	private FVector MispredictionCorrectionVelocity;

	float PredictionStartTime;
	float PredictionDuration;

	FHazeAcceleratedVector AccPredictionOffset;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if(!Network::IsGameNetworked())
			return;

		BossBall = Cast<APinballBossBall>(Owner);
		LaunchedComp = UPinballBossBallLaunchedComponent::Get(BossBall);
		SyncComp = UPinballBossBallSyncComponent::Create(BossBall, n"PredictionSyncComp");

		if(HasControl())
			return;

		auto TeleportComp = UTeleportResponseComponent::GetOrCreate(Owner);
		TeleportComp.OnTeleported.AddUFunction(this, n"OnTeleported");

		MovementSettings = UPinballMovementSettings::GetSettings(BossBall);

		Proxy = SpawnActor(APinballBossBallProxy, BossBall.ActorLocation, BossBall.ActorRotation, bDeferredSpawn = true);
		Proxy.RepresentedActor = BossBall;
		FinishSpawningActor(Proxy);

#if !RELEASE
		TEMPORAL_LOG(this, Owner, "PinballBossBallPrediction");
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
			SyncAdditionalInformation();
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

		if (LaunchedComp.LaunchedPredictedOtherSideTime > 0.0)
		{
			ModifyLatestAvailableBossBallActorPosition_Launch(LatestActorPosition, LatestCrumbTime);
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
		FScopeCycleCounter CycleCounter(STAT_PinballBossBallPredictionComponent_PostInit);

		check(Network::IsGameNetworked());
		check(Pinball::GetPaddlePlayer().HasControl());

		FHazeSyncedActorPosition ActorPosition;
		float CrumbTime = 0.0;
		TryGetLatestAvailableActorPosition(ActorPosition, CrumbTime);

		PredictionDuration = GetPredictionDuration();
		PredictionStartTime = InPredictionLoopEndTime - PredictionDuration;

		FPinballBossBallSyncedData SyncedData = GetLatestSyncedData();

		Proxy.Initialize(
			ActorPosition,
			SyncedData,
			CrumbTime,
			PredictionDuration
		);

		Proxy.PredictedPath.CorrectionVelocity = MispredictionCorrectionVelocity;

		// SubframeNumber should be reset in Proxy.Initialize()
		check(Proxy.SubframeNumber == 0);
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
		FScopeCycleCounter CycleCounter(STAT_PinballBossBallPredictionComponent_PostFinalize);

		Proxy.Finalize(PredictionDuration);

		InterpolateToPrediction(Proxy.PredictedPath, Time::GetActorDeltaSeconds(BossBall));
		MispredictionCorrectionVelocity = Proxy.PredictedPath.CorrectionVelocity;

#if !RELEASE
		TemporalLogFinalState();
#endif
	}

	private void SyncAdditionalInformation() const
	{
		check(HasControl());

		FPinballBossBallSyncedData SyncedData;
		SyncedData.MovementData = FPinballBossBallSyncedMovementData(BossBall);
		SyncedData.LaunchedData = FPinballBossBallSyncedLaunchedData(LaunchedComp);

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this, "Synced Data");
		SyncedData.LogToTemporalLog(TemporalLog, HasControl(), Time::ThisSideCrumbTrailSendTime);
#endif

		SyncComp.SetCrumbValueStruct(SyncedData);
	}

	private void ModifyLatestAvailableBossBallActorPosition_Launch(
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
				const float PredictTimeToBlendAway = Math::Max(HalfPing + LaunchedComp.PredictedLaunchAheadTime, 0);

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

	FPinballBossBallSyncedData GetLatestSyncedData(bool bAllowPredictionToModify = true) const
	{
		float CrumbTime = 0;
		FPinballBossBallSyncedData SyncedData;
		SyncComp.GetLatestAvailableData(SyncedData, CrumbTime);

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this, "GetLatestSyncedData");
#endif

		if(!SyncComp.HasUsableDataInCrumbTrail())
		{
#if !RELEASE
			SyncedData.LogToTemporalLog(TemporalLog, HasControl(), CrumbTime);
#endif

			// Don't allow modification if we don't have any synced data yet
			return SyncedData;
		}

		if(bAllowPredictionToModify)
		{
			if(LaunchedComp.LaunchedPredictedOtherSideTime > 0 && LaunchedComp.LaunchedPredictedOtherSideTime > CrumbTime - 0.15)
			{
				ModifyLatestSyncedData_Launch(SyncedData);
			}
		}

#if !RELEASE
		SyncedData.LogToTemporalLog(TemporalLog, HasControl(), CrumbTime);
#endif

		return SyncedData;
	}

	private void ModifyLatestSyncedData_Launch(FPinballBossBallSyncedData& SyncedData) const
	{
		// No ground contact during launch
		SyncedData.MovementData.GroundContact = FHitResult();
	}

	FPinballPredictedPath GetPredictedPath() const
	{
		return Proxy.PredictedPath;
	}

	private void InterpolateToPrediction(FPinballPredictedPath& PredictedPath, float DeltaTime) const
	{
		FScopeCycleCounter CycleCounter(STAT_PinballBossBallPredictionComponent_InterpolateToPrediction);

		FVector CurrentLocation = BossBall.ActorLocation;

		const float OptimalTime = PredictionDuration;
		const FVector PredictOptimalLocation = PredictedPath.GetLocationAtTime(PredictionDuration);

		float ClosestSplineTime = PredictedPath.GetTimeClosestToLocation(CurrentLocation);
		FVector ClosestSplineLocation = PredictedPath.GetLocationAtTime(ClosestSplineTime);
		float DistanceToClosestSplineLocation = ClosestSplineLocation.Distance(CurrentLocation);

		// Decay our offset away from the spline
		FVector MaintainedOffset = (BossBall.ActorLocation - ClosestSplineLocation);
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
			.Sphere(f"Current Location", CurrentLocation, APinballBossBall::Radius)
			.DirectionalArrow(f"Current Velocity", CurrentLocation, BossBall.ActorVelocity)
			.Value(f"Closest Spline Time", ClosestSplineTime)
			.Value(f"Optimal Time", OptimalTime)
			.Value(f"Anchor Time", AnchorTime)
			.Value(f"Spline Target Time Length", SplineTargetTimeLength)
			.Value(f"Spline Total Time", PredictedPath.GetTotalTime())
			.Sphere(f"Predict Optimal Location", PredictOptimalLocation, APinballBossBall::Radius, FLinearColor::Red)
			.Sphere(f"Closest Spline Location", ClosestSplineLocation, APinballBossBall::Radius, FLinearColor::DPink)
			.Value(f"Distance To Closest Spline Location", DistanceToClosestSplineLocation)
			.Sphere(f"Spline Predicted Location", SplinePredictedLocation, APinballBossBall::Radius, FLinearColor::Purple)
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
		FScopeCycleCounter CycleCounter(STAT_PinballBossBallPredictionComponent_TemporalLogFinalState);

		FHazeSyncedActorPosition ActorPosition;
		float CrumbTime = 0;
		TryGetLatestAvailableActorPosition(ActorPosition, CrumbTime);

		auto PredictedPath = GetPredictedPath();

		TEMPORAL_LOG(this).Page("Launch")
			.Sphere(f"Launch Location", LaunchedComp.LaunchData.LaunchLocation, APinballBossBall::Radius, FLinearColor::Yellow)
			.Value(f"Launch Predicted Time", LaunchedComp.LaunchedPredictedOtherSideTime)
		;


		TEMPORAL_LOG(this).Page("Paddle")
			.DirectionalArrow(f"Velocity", BossBall.ActorLocation, BossBall.ActorVelocity)
			.Sphere(f"Latest Location", ActorPosition.WorldLocation, APinballBossBall::Radius)
			.DirectionalArrow(f"Latest Velocity", ActorPosition.WorldLocation, ActorPosition.WorldVelocity)
			.Value(f"Latest Crumb Time", CrumbTime)
		;

		// TEMPORAL_LOG(this).Page("Launch")
		// 	.Value(f"Is Launched", LaunchedComp.bIsLaunched)
		// ;

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
			
			.Sphere(f"Actor Location", BossBall.ActorLocation, 40, FLinearColor::Red, 3)

#if EDITOR
			.Sphere(f"Other Side Location", GetOtherSideLocation(), 40, FLinearColor::LucBlue, 3)
#endif

			.Sphere(f"Unmodified Latest Data Location", UnmodifiedActorPosition.WorldLocation, 40, FLinearColor::Green, 3)
			.Value(f"Unmodified Latest Crumb Time", UnmodifiedCrumbTime)

#if EDITOR
			.Value(f"Interpolated Error", GetOtherSideLocation() - BossBall.ActorLocation)
#endif
			.Value(f"PredictionDuration", PredictionDuration)
		;
	}
#endif
};