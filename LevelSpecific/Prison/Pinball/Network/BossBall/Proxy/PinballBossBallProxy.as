const FStatID STAT_PinballBossBallProxy_Init(n"PinballBossBallProxy_Init");
const FStatID STAT_PinballBossBallProxy_PerformTick(n"PinballBossBallProxy_PerformTick");
const FStatID STAT_PinballBossBallProxy_Finalize(n"PinballBossBallProxy_Finalize");
const FStatID STAT_PinballBossBallProxy_LogInitialize(n"PinballBossBallProxy_LogInitialize");
const FStatID STAT_PinballBossBallProxy_LogPreTick(n"PinballBossBallProxy_LogPreTick");
const FStatID STAT_PinballBossBallProxy_LogPostTick(n"PinballBossBallProxy_LogPostTick");
const FStatID STAT_PinballBossBallProxy_LogFinalize(n"PinballBossBallProxy_LogFinalize");

UCLASS(NotBlueprintable)
class APinballBossBallProxy : APinballProxy
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent CollisionComponent;
	default CollisionComponent.CollisionProfileName = n"EnemyCharacter";
	default CollisionComponent.SphereRadius = APinballBossBall::Radius;

	UPROPERTY(DefaultComponent)
	UPinballPredictabilitySystemComponent PredictabilityComp;
	default PredictabilityComp.PredictabilityClasses.Add(UPinballBossBallMovePredictability);
	default PredictabilityComp.PredictabilityClasses.Add(UPinballBossBallAirMovePredictability);

	UPROPERTY(DefaultComponent)
	UPinballBossBallProxyMovementComponent MoveComp;
	default MoveComp.FollowEnablement.DefaultValue = EMovementFollowEnabledStatus::FollowDisabled;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UMovementInstigatorLogComponent MovementInstigatorLogComp;

	UPROPERTY(DefaultComponent, Attach = CollisionComponent)
	UPinballPredictionRecordTransformComponent PredictionRecordTransformComp;
	default PredictionRecordTransformComp.bPlaybackInPrediction = false;

	UPROPERTY(DefaultComponent)
	UPinballTemporalLogSubframeTransformLoggerComponent SubframeTransformLoggerComp;
#endif

	// Launched
	UPROPERTY(DefaultComponent)
	UPinballBossBallProxyLaunchedComponent LaunchedComp;
	default PredictabilityComp.PredictabilityClasses.Add(UPinballBossBallLaunchedPredictability);

	// Initial
	FPinballBossBallSyncedData InitialSyncedData;

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

#if EDITOR
		TemporalLog::RegisterExtender(this, n"PinballTemporalSubframeExtender");
		SubframeTransformLoggerComp.OnScrubToSubframeDelegate.BindUFunction(this, n"OnScrub");
#endif
	}

	void Initialize(
		FHazeSyncedActorPosition InitialActorPosition,
		FPinballBossBallSyncedData InInitialSyncedData,
		float InInitialGameTime,
		float InPredictionDuration,
	)
	{
		FScopeCycleCounter CycleCounter(STAT_PinballBossBallProxy_Init);

		// Reset all movement state
		MoveComp.Reset(true, bValidateGround = false);

		// We need to manually transform our relative synced values to world values, since the component position might be different in the initial
		// subframe than when we called GetPosition on the synced actor position component.
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

		// Set initial movement state
		SetActorLocation(InitialWorldLocation);
		SetActorVelocity(InitialWorldVelocity);
		MoveComp.InitMovementState(InitialSyncedData.MovementData);

		InitialGameTime = InInitialGameTime;
		SubframeNumber = 0;

		// Reset predicted path
		PredictedPath = FPinballPredictedPath();
		PredictedPath.Init(InitialWorldLocation, InitialActorPosition.WorldVelocity, InPredictionDuration);

		// Prepare tick values
		TickGameTime = InitialGameTime;

		PredictabilityComp.InitStateFromControl();

#if !RELEASE
		LogInitialize(InPredictionDuration, InitialActorPosition);
#endif
	}

	void PerformTick(uint InSubframeNumber, float InPredictionTime, float InDeltaTime)
	{
		FScopeCycleCounter CycleCounter(STAT_PinballBossBallProxy_PerformTick);

		SubframeNumber = InSubframeNumber;
		TickGameTime = InPredictionTime;
		DeltaTime = InDeltaTime;

		if(DeltaTime < KINDA_SMALL_NUMBER)
			return;

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
		PredictedPath.AddPoint(ActorLocation, TickGameTime - InitialGameTime);
	}

	void Finalize(float PredictDuration)
	{
		FScopeCycleCounter CycleCounter(STAT_PinballBossBallProxy_Finalize);

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
			PredictedPath.AddPoint(
				ActorLocation,
				PredictDuration,
			);
		}

		PredictedPath.FinishCreation(ActorVelocity);

		MoveComp.PostPrediction();

#if !RELEASE
		LogFinalize();
#endif
	}

#if EDITOR
	UFUNCTION()
	private void OnScrub(FTransform WorldTransform)
	{
		Pinball::GetBossBall().SetActorLocationAndRotation(
			WorldTransform.Location,
			WorldTransform.Rotation
		);
	}
#endif

#if !RELEASE
	private void LogInitialize(float PredictDuration, FHazeSyncedActorPosition InitialActorPosition) const
	{
		FScopeCycleCounter CycleCounter(STAT_PinballBossBallProxy_LogInitialize);

		FTemporalLog InitialLog = GetInitialLog();

		InitialLog
			.Value(f"Predict Duration", PredictDuration)
			.Sphere("Location", ActorLocation, CollisionComponent.SphereRadius, FLinearColor::White)
			.DirectionalArrow("Velocity", ActorLocation, ActorVelocity)
			.Value("Initial Game Time", InitialGameTime)
			.Value("Initial Frame Number", SubframeNumber)

			.Value("Initial Synced Actor Position;RelativeComponent", InitialActorPosition.RelativeComponent)
		;

		MoveComp.LogInitial(InitialLog);
	}

	private void LogPreTick()
	{
		FScopeCycleCounter CycleCounter(STAT_PinballBossBallProxy_LogPreTick);

		FTemporalLog PreTickLog = GetSubframeLog().Page("Pre Tick");

		PreTickLog
			.Sphere(f"Location", ActorLocation, CollisionComponent.SphereRadius, FLinearColor::White)
			.Arrow(f"Velocity", ActorLocation, ActorLocation + ActorVelocity)
			.HitResults(f"GroundContact", MoveComp.GroundContact.ConvertToHitResult(), MoveComp.CollisionShape)
			.Value(f"DeltaTime", DeltaTime)

			.Value(f"Tick Game Time", TickGameTime)
			.Value(f"Tick Frame Number", SubframeNumber)
		;
	}

	private void LogPostTick()
	{
		FScopeCycleCounter CycleCounter(STAT_PinballBossBallProxy_LogPostTick);

		FTemporalLog PostTickLog = GetSubframeLog().Page("Post Tick");

		PostTickLog
			.Sphere(f"Location", ActorLocation, CollisionComponent.SphereRadius, FLinearColor::White)
			.Arrow(f"Velocity", ActorLocation, ActorLocation + ActorVelocity)
			.HitResults(f"GroundContact", MoveComp.GroundContact.ConvertToHitResult(), MoveComp.CollisionShape)
			.Value(f"DeltaTime", DeltaTime)

			.Value(f"Tick Game Time", TickGameTime)
			.Value(f"Tick Frame Number", SubframeNumber)
		;

		MoveComp.LogPostTick(GetSubframeLog());
	}

	private void LogFinalize()
	{
		FScopeCycleCounter CycleCounter(STAT_PinballBossBallProxy_LogFinalize);

		FTemporalLog FinalizeLog = TEMPORAL_LOG(this).Page("Finalize");

		FinalizeLog
			.Value(f"Subframes", SubframeNumber)
			.DirectionalArrow(f"Velocity", ActorLocation, ActorVelocity)
			.RuntimeSpline(f"Predicted Path Spline", PredictedPath.GetSpline())

			.Sphere(f"Extrapolated Location", PredictedPath.GetExtrapolatedLocation(), CollisionComponent.SphereRadius, FLinearColor::Yellow, 3)
			.Sphere(f"Spline End Location", PredictedPath.GetSpline().GetLocation(1), CollisionComponent.SphereRadius, FLinearColor::White, 3)
			.Sphere(f"Interpolated Location", PredictedPath.GetLocationAtTime(Time::OtherSideCrumbTrailSendTimePrediction), CollisionComponent.SphereRadius, FLinearColor::White, 3)
		;
	}
#endif
};