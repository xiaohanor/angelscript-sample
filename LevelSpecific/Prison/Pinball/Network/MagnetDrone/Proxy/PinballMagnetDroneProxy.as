const FStatID STAT_PinballMagnetDroneProxy_Init(n"PinballMagnetDroneProxy_Init");
const FStatID STAT_PinballMagnetDroneProxy_PerformTick(n"PinballMagnetDroneProxy_PerformTick");
const FStatID STAT_PinballMagnetDroneProxy_Finalize(n"PinballMagnetDroneProxy_Finalize");
const FStatID STAT_PinballMagnetDroneProxy_LogInitialize(n"PinballMagnetDroneProxy_LogInitialize");
const FStatID STAT_PinballMagnetDroneProxy_LogPreTick(n"PinballMagnetDroneProxy_LogPreTick");
const FStatID STAT_PinballMagnetDroneProxy_LogPostTick(n"PinballMagnetDroneProxy_LogPostTick");
const FStatID STAT_PinballMagnetDroneProxy_LogFinalize(n"PinballMagnetDroneProxy_LogFinalize");

UCLASS(NotBlueprintable)
class APinballMagnetDroneProxy : APinballProxy
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent CollisionComponent;
	default CollisionComponent.CollisionProfileName = n"PlayerCharacter";
	default CollisionComponent.SphereRadius = MagnetDrone::Radius;

	UPROPERTY(DefaultComponent)
	UPinballPredictabilitySystemComponent PredictabilityComp;
	default PredictabilityComp.PredictabilityClasses.Add(UPinballProxyGroundPredictability);
	default PredictabilityComp.PredictabilityClasses.Add(UPinballProxyAirPredictability);

	UPROPERTY(DefaultComponent)
	UPinballMagnetDroneProxyMovementComponent MoveComp;
	default MoveComp.FollowEnablement.DefaultValue = EMovementFollowEnabledStatus::FollowDisabled;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UMovementInstigatorLogComponent MovementInstigatorLogComp;

	UPROPERTY(DefaultComponent, Attach = CollisionComponent)
	UPinballPredictionRecordTransformComponent PredictionRecordTransformComp;
	default PredictionRecordTransformComp.bPlaybackInPrediction = false;
	default PredictionRecordTransformComp.bHazeEditorOnlyDebugBool = true;

	UPROPERTY(DefaultComponent)
	UPinballTemporalLogSubframeTransformLoggerComponent SubframeTransformLoggerComp;

	UPROPERTY(DefaultComponent)
	UPinballTemporalLogComponent TemporalLogComp;
#endif

	// Launched
	UPROPERTY(DefaultComponent)
	UPinballProxyLaunchedComponent LaunchedComp;
	default PredictabilityComp.PredictabilityClasses.Add(UPinballProxyPushedByPlungerPredictability);
	default PredictabilityComp.PredictabilityClasses.Add(UPinballProxyLaunchedPredictability);

	// Rail
	UPROPERTY(DefaultComponent)
	UPinballProxyRailPredictionComponent RailComp;
	default PredictabilityComp.PredictabilityClasses.Add(UPinballProxyEnterRailPredictability);
	default PredictabilityComp.PredictabilityClasses.Add(UPinballProxyRailEnterSyncPointPredictability);
	default PredictabilityComp.PredictabilityClasses.Add(UPinballProxyRailPredictability);
	default PredictabilityComp.PredictabilityClasses.Add(UPinballProxyRailExitSyncPointPredictability);

	// Magnet Attraction
	UPROPERTY(DefaultComponent)
	UPinballProxyMagnetAttractionComponent AttractionComp;
	default PredictabilityComp.PredictabilityClasses.Add(UPinballProxyMagnetAttractionModesPredictability);

	// Magnet Attached
	UPROPERTY(DefaultComponent)
	UPinballProxyMagnetAttachedComponent AttachedComp;
	default PredictabilityComp.PredictabilityClasses.Add(UPinballProxyMagnetMovePredictability);

	// Initial
	USceneComponent SyncRelativeComponent;
	FPinballPredictionSyncedData InitialSyncedData;
	float InitialHorizontalInput;
	float InitialVerticalInput;
	float InputAcceptDuration;

	// From FindInitialImpacts
	FPinballBallLaunchData InitialLaunchData;

	// Tick
	float TickHorizontalInput;
	float TickVerticalInput;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp.SetupShapeComponent(CollisionComponent);

		// FB TODO: Can I do this?
		auto GravitySettings = UMovementGravitySettings::GetSettings(RepresentedActor);
		auto StandardSettings = UMovementStandardSettings::GetSettings(RepresentedActor);
		auto SweepingSettings = UMovementSweepingSettings::GetSettings(RepresentedActor);

		ApplySettings(GravitySettings, this);
		ApplySettings(StandardSettings, this);
		ApplySettings(SweepingSettings, this);

		auto Manager = Pinball::Prediction::GetManager();
		Manager.PreRollback.AddUFunction(this, n"PreRollback");
		Manager.PostRollback.AddUFunction(this, n"PostRollback");
		
#if EDITOR
		TemporalLog::RegisterExtender(this, n"PinballTemporalSubframeExtender");
		SubframeTransformLoggerComp.OnScrubToSubframeDelegate.BindUFunction(this, n"OnScrub");
#endif
	}

	UFUNCTION()
	private void PreRollback()
	{
		MoveComp.ApplyFollowEnabledOverride(FInstigator(this, n"Rollback"), EMovementFollowEnabledStatus::FollowDisabled, EInstigatePriority::Override);
	}

	UFUNCTION()
	private void PostRollback()
	{
		MoveComp.ClearFollowEnabledOverride(FInstigator(this, n"Rollback"));
	}

	void Initialize(
		FHazeSyncedActorPosition InitialActorPosition,
		FPinballPredictionSyncedData InInitialSyncedData,
		float InInitialGameTime,
		float InPredictionDuration,
		float InInitialHorizontalInput,
		float InInitialVerticalInput,
		float MovementInputHeldDuration,
	)
	{
		FScopeCycleCounter CycleCounter(STAT_PinballMagnetDroneProxy_Init);

		// Reset all movement state
		MoveComp.Reset(true, bValidateGround = false);
		MoveComp.ProxyLastMoveFrame = 0;

		// We need to manually transform our relative synced values to world values, since the component position might be different in the initial
		// subframe than when we called GetPosition on the synced actor position component.
		SyncRelativeComponent = InitialActorPosition.RelativeComponent;
		FVector InitialWorldLocation;
		FVector InitialWorldVelocity;
		switch(InitialActorPosition.RelativeType)
		{
			case EHazeActorPositionRelativeType::RelativeToComponent:
			case EHazeActorPositionRelativeType::RelativeToComponentWorldRotation:
				InitialWorldLocation = InitialActorPosition.RelativeComponent.WorldTransform.TransformPositionNoScale(InitialActorPosition.RelativeLocation);
				InitialWorldVelocity = InitialActorPosition.RelativeComponent.WorldTransform.TransformVectorNoScale(InitialActorPosition.RelativeVelocity);
				break;

			default:
				InitialWorldLocation = InitialActorPosition.WorldLocation;
				InitialWorldVelocity = InitialActorPosition.WorldVelocity;
		}

		InitialSyncedData = InInitialSyncedData;

		MoveComp.ApplyFollowEnabledOverride(
			FInstigator(this, n"Prediction"),
			EMovementFollowEnabledStatus::FollowEnabled,
			EInstigatePriority::High
		);

		// Set initial movement state
		SetActorLocation(InitialWorldLocation);
		SetActorVelocity(InitialWorldVelocity);
		MoveComp.InitMovementState(InitialSyncedData.MovementData);

		/**
		* Because at very low ping, the other side might hit and reflect of off impacts before us, we must
		* check before we move if there is anything for us to impact
		*/
		InitialLaunchData = FPinballBallLaunchData();
		TriggerInitialLaunches();

		InitialHorizontalInput = InInitialHorizontalInput;
		InitialVerticalInput = InInitialVerticalInput;
		InitialGameTime = InInitialGameTime;
		SubframeNumber = 0;

		// If we haven't been holding this input for a little bit of time, predict
		// as if we're going to release it again soon. This prevents a bit of jitter
		InputAcceptDuration = Math::GetMappedRangeValueClamped(
			FVector2D(0.0, 0.15),
			FVector2D(0.016, 1.0),
			MovementInputHeldDuration
		);

		// Reset predicted path
		PredictedPath = FPinballPredictedPath();
		PredictedPath.Init(InitialWorldLocation, InitialActorPosition.WorldVelocity, InPredictionDuration);

		// Prepare tick values
		TickHorizontalInput = InitialHorizontalInput;
		TickVerticalInput = InitialVerticalInput;
		TickGameTime = InitialGameTime;

		PredictabilityComp.InitStateFromControl();

#if !RELEASE
		LogInitialize(InPredictionDuration, InitialActorPosition);
#endif
	}

	/**
	 * Because at very low ping, the other side might hit and reflect of off impacts before us, we must
	 * check before we move if there is anything for us to impact
	 */
	private void TriggerInitialLaunches()
	{
		FPinballBallLaunchData LaunchData;

		FHazeTraceSettings Trace = Trace::InitObjectType(EObjectTypeQuery::WorldDynamic);
		Trace.UseSphereShape(MagnetDrone::Radius * 1.5);
		FOverlapResultArray Overlaps = Trace.QueryOverlaps(ActorLocation);
		for(const FOverlapResult& Overlap : Overlaps)
		{
			if(HitBouncePad(Overlap.Actor, LaunchData))
				break;

			if(HitBreakableLock(Overlap.Actor, LaunchData))
				break;
		}

		if(LaunchData.IsValid())
		{
			InitialLaunchData = LaunchData;

			SetActorLocation(InitialLaunchData.LaunchLocation);
			SetActorVelocity(InitialLaunchData.LaunchVelocity);
		}
	}

	private bool HitBouncePad(AActor Actor, FPinballBallLaunchData&out OutLaunchData) const
	{
		auto BouncePad = Cast<APinballBouncePad>(Actor);
		if(BouncePad == nullptr)
			return false;

		FPinballBouncePadHitResult BouncePadHitResult;
		if(!BouncePad.CalculateBouncePadHitResult(BouncePadHitResult))
			return false;

		FVector LaunchVelocity = BouncePadHitResult.GetImpulseVector();

		FPinballBallLaunchData LaunchData(
			BouncePadHitResult.LaunchLocation,
			ActorLocation,
			LaunchVelocity,
			BouncePad.LauncherComp,
			true
		);

		OutLaunchData = LaunchData;
		return true;
	}

	private bool HitBreakableLock(AActor Actor, FPinballBallLaunchData&out OutLaunchData) const
	{
		auto BreakableLock = Cast<APinballBreakableLock>(Actor);
		if(BreakableLock == nullptr)
			return false;

		if(BreakableLock.bBroken)
			return false;

		const FVector DirFromLock = (ActorLocation - BreakableLock.ActorLocation);
		const FVector Normal = DirFromLock.VectorPlaneProject(FVector::ForwardVector);
		const FVector LaunchDir = ActorVelocity.GetReflectionVector(Normal).GetSafeNormal();

		const FVector LaunchVelocity = LaunchDir * BreakableLock.LaunchPower;

		FPinballBallLaunchData LaunchData = FPinballBallLaunchData(
			ActorLocation,
			ActorLocation,
			LaunchVelocity,
			BreakableLock.LauncherComp,
			true
		);

		OutLaunchData = LaunchData;
		return true;
	}

	void PerformTick(uint InSubframeNumber, float InPredictionTime, float InDeltaTime)
	{
		FScopeCycleCounter CycleCounter(STAT_PinballMagnetDroneProxy_PerformTick);

		SubframeNumber = InSubframeNumber;
		TickGameTime = InPredictionTime;
		DeltaTime = InDeltaTime;

		if(DeltaTime < KINDA_SMALL_NUMBER)
			return;

		TickHorizontalInput = InitialHorizontalInput;
		TickVerticalInput = InitialVerticalInput;
		if ((TickGameTime - InitialGameTime) > InputAcceptDuration)
		{
			TickHorizontalInput = 0;
			TickVerticalInput = 0;
		}

#if !RELEASE
		LogPreTick();
#endif

		PredictabilityComp.TickFromPrediction(DeltaTime);
		
#if !RELEASE
		LogPostTick();
#endif

		TickGameTime += DeltaTime;

		// Need to record the position with the game time _after_ adding delta time,
		// since this is the position after moving, not the position before moving
		PredictedPath.AddPoint(
			ActorLocation,
			TickGameTime - InitialGameTime,
		);
	}

	void Finalize(float PredictDuration)
	{
		FScopeCycleCounter CycleCounter(STAT_PinballMagnetDroneProxy_Finalize);

		PredictabilityComp.DispatchPostPrediction();

		if(PredictedPath.GetSpline().Points.Num() < 2)
		{
			PredictedPath.AddPoint(
				ActorLocation + ActorVelocity * PredictDuration,
				PredictDuration,
			);
		}
		else
		{
			// Record last point
			PredictedPath.AddPoint(
				ActorLocation,
				PredictDuration,
			);
		}

		PredictedPath.FinishCreation(ActorVelocity);

		MoveComp.PostPrediction();

		MoveComp.ClearFollowEnabledOverride(FInstigator(this, n"Prediction"));

#if !RELEASE
		LogFinalize();
#endif
	}

#if EDITOR
	UFUNCTION()
	private void OnScrub(FTransform WorldTransform)
	{
		Pinball::GetBallPlayer().MeshOffsetComponent.SetWorldTransform(WorldTransform);
	}
#endif

#if !RELEASE
	private void LogInitialize(float PredictDuration, FHazeSyncedActorPosition InitialSyncedActorPosition) const
	{
		FScopeCycleCounter CycleCounter(STAT_PinballMagnetDroneProxy_LogInitialize);

		FTemporalLog InitialLog = GetInitialLog();

		InitialLog
			.Value(f"Predict Duration", PredictDuration)
			.Sphere("Location", ActorLocation, CollisionComponent.SphereRadius, FLinearColor::White)
			.DirectionalArrow("Velocity", ActorLocation, ActorVelocity)
			.Value("Initial Horizontal Input", InitialHorizontalInput)
			.Value("Initial Vertical Input", InitialVerticalInput)
			.Value("Input Accept Duration", InputAcceptDuration)
			.Value("Initial Game Time", InitialGameTime)
			.Value("Initial Frame Number", SubframeNumber)

			.Value("Initial Synced Actor Position;RelativeComponent", InitialSyncedActorPosition.RelativeComponent)
		;

		if(InitialSyncedActorPosition.RelativeComponent != nullptr)
		{
			InitialLog.Box("Initial Synced Actor Position;RelativeComponent Bounds", InitialSyncedActorPosition.RelativeComponent.Bounds.Origin, InitialSyncedActorPosition.RelativeComponent.Bounds.BoxExtent, FRotator::ZeroRotator);
		}

		MoveComp.LogInitial(InitialLog);
	}

	private void LogPreTick()
	{
		FScopeCycleCounter CycleCounter(STAT_PinballMagnetDroneProxy_LogPreTick);

		FTemporalLog PreTickLog = GetSubframeLog().Page("Pre Tick");

		PreTickLog
			.Sphere(f"Location", ActorLocation, CollisionComponent.SphereRadius, FLinearColor::White)
			.Arrow(f"Velocity", ActorLocation, ActorLocation + ActorVelocity)
			.HitResults(f"GroundContact", MoveComp.GroundContact.ConvertToHitResult(), MoveComp.CollisionShape)
			.Value(f"DeltaTime", DeltaTime)

			.Value(f"Tick Horizontal Input", TickHorizontalInput)
			.Value(f"Tick Vertical Input", TickVerticalInput)
			.Value(f"Tick Game Time", TickGameTime)
			.Value(f"Tick Frame Number", SubframeNumber)
		;
	}

	private void LogPostTick()
	{
		FScopeCycleCounter CycleCounter(STAT_PinballMagnetDroneProxy_LogPostTick);

		FTemporalLog PostTickLog = GetSubframeLog().Page("Post Tick");

		PostTickLog
			.Sphere(f"Location", ActorLocation, CollisionComponent.SphereRadius, FLinearColor::White)
			.Arrow(f"Velocity", ActorLocation, ActorLocation + ActorVelocity)
			.HitResults(f"GroundContact", MoveComp.GroundContact.ConvertToHitResult(), MoveComp.CollisionShape)
			.Value(f"DeltaTime", DeltaTime)

			.Value(f"Tick Horizontal Input", TickHorizontalInput)
			.Value(f"Tick Vertical Input", TickVerticalInput)
			.Value(f"Tick Game Time", TickGameTime)
			.Value(f"Tick Frame Number", SubframeNumber)
		;

		MoveComp.LogPostTick(GetSubframeLog());
	}

	private void LogFinalize()
	{
		FScopeCycleCounter CycleCounter(STAT_PinballMagnetDroneProxy_LogFinalize);

		FTemporalLog FinalizeLog = TEMPORAL_LOG(this).Page("Finalize");

		FinalizeLog
			.Value(f"Subframes", SubframeNumber)
			.DirectionalArrow(f"Velocity", ActorLocation, ActorVelocity)
			.RuntimeSpline(f"Predicted Path Spline", PredictedPath.GetSpline())

			.Sphere(f"Extrapolated Location", PredictedPath.GetExtrapolatedLocation(), CollisionComponent.SphereRadius, FLinearColor::Yellow, 3)
			.Sphere(f"Spline End Location", PredictedPath.GetSpline().GetLocation(1), CollisionComponent.SphereRadius, FLinearColor::White, 3)
			.Sphere(f"Interpolated Location", PredictedPath.GetLocationAtTime(Time::OtherSideCrumbTrailSendTimePrediction), CollisionComponent.SphereRadius, FLinearColor::White, 3)
			
			.Value("Final Synced Actor Position;RelativeComponent", SyncRelativeComponent)
		;

#if EDITOR
		for(int i = 0; i < MoveComp.DebugMovementSweeps.Num(); i++)
		{
			FinalizeLog.Page("Sweeps").HitResults(f"Sweep {i}:", MoveComp.DebugMovementSweeps[i].ConvertToHitResult(), MoveComp.CollisionShape);
		}
#endif

		if(SyncRelativeComponent != nullptr)
		{
			FinalizeLog.Box("Final Synced Actor Position;RelativeComponent Bounds", SyncRelativeComponent.Bounds.Origin, SyncRelativeComponent.Bounds.BoxExtent, FRotator::ZeroRotator);
		}
	}
#endif
};