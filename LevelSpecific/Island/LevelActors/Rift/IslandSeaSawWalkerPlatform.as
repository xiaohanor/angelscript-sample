event void FIslandSeaSawWalkerPlatformSignature();

class AIslandSeaSawWalkerPlatform : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent BaseComp;

	UPROPERTY(DefaultComponent, Attach = "BaseComp")
	USceneComponent ObstacleComp;

	UPROPERTY(DefaultComponent, Attach = "ObstacleComp")
	UHazeMovablePlayerTriggerComponent KillTrigger;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ObstacleActionQueue;

	UPROPERTY()
	FIslandSeaSawWalkerPlatformSignature OnReachedDestination;

	UPROPERTY()
	FIslandSeaSawWalkerPlatformSignature OnStartMoving;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve MoveCurve;
	default MoveCurve.AddDefaultKey(0.0, 0.0);
	default MoveCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve ObstacleMoveCurve;
	default ObstacleMoveCurve.AddDefaultKey(0.0, 0.0);
	default ObstacleMoveCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	float MoveDuration = 3.0;

	UPROPERTY(EditAnywhere)
	float ObstacleMoveDuration = 2.5;

	UPROPERTY(EditAnywhere)
	float PercentageBeforeMovingObstacle = 0.7;

	UPROPERTY(EditAnywhere)
	float DelayDuration = 0.5;

	UPROPERTY(EditAnywhere)
	bool bIsActivated = true;

	UPROPERTY(EditAnywhere)
	float OffsetDuration = SMALL_NUMBER;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffect")
	TSubclassOf<UDeathEffect> DeathEffect;

	FQuat StartingRotation;
	FQuat EndingRotation;
	float StartTime = 0.0;
	float MoveAlpha = 0.0;
	float ObstacleMoveAlpha = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FTransform StartingTransform = Root.GetWorldTransform();
		StartingRotation = StartingTransform.GetRotation();

		FTransform EndingTransform = DestinationComp.GetWorldTransform();
		EndingRotation = EndingTransform.GetRotation();

		KillTrigger.OnPlayerEnter.AddUFunction(this, n"OnEnterKillTrigger");

		if(bIsActivated)
			LocalActivate();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float DelayBeforeMovingObstacle = MoveDuration * PercentageBeforeMovingObstacle;
		ActionQueue.ScrubTo(Time::PredictedGlobalCrumbTrailTime - OffsetDuration - StartTime);
		ObstacleActionQueue.ScrubTo(Time::PredictedGlobalCrumbTrailTime - OffsetDuration - StartTime - DelayBeforeMovingObstacle);

#if !RELEASE
		TEMPORAL_LOG(this)
			.Value("Move Alpha", MoveAlpha)
			.Value("Obstacle Move Alpha", ObstacleMoveAlpha)
		;
#endif
	}

	UFUNCTION()
	void BP_Activate()
	{
		if (!HasControl())
			return;

		CrumbActivate(Time::PredictedGlobalCrumbTrailTime);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbActivate(float In_StartTime)
	{
		StartTime = In_StartTime;
		LocalActivate();
	}

	private void LocalActivate()
	{
		bIsActivated = true;
		SetActorTickEnabled(true);

		ActionQueue.SetLooping(true);
		ActionQueue.Event(this, n"StartMoving");
		ActionQueue.Duration(MoveDuration, this, n"OnUpdate");
		ActionQueue.Event(this, n"StopMoving");
		ActionQueue.Idle(DelayDuration);
		ActionQueue.Event(this, n"StartMoving");
		ActionQueue.ReverseDuration(MoveDuration, this, n"OnUpdate");
		ActionQueue.Event(this, n"StopMoving");
		ActionQueue.Idle(DelayDuration);

		// Two timelines:
		// M = MoveDuration
		// O = ObstacleMoveDuration
		// D = DelayDuration
		// W = ObstacleDelay (unknown)
		// S = DelayBeforeMovingObstacle = MoveDuration * PercentageBeforeMovingObstacle (subtracted from the scrub in tick).
		// W = M + D + S - S - O
		// W = M + D - O (simplified since S cancels out)
		//
		// I----- M -----I- D -I----- M -----I- D -I----- M -----I (ActionQueue)
        // I--- S ----I---- O ----I-- W --I---- O ----I-- W --I (ObstacleActionQueue)
		//
		float ObstacleDelay = MoveDuration + DelayDuration - ObstacleMoveDuration;
		ObstacleActionQueue.SetLooping(true);
		ObstacleActionQueue.Event(this, n"ObstacleStartMoving");
		ObstacleActionQueue.Duration(ObstacleMoveDuration, this, n"OnObstacleUpdate");
		ObstacleActionQueue.Event(this, n"ObstacleStopMoving");
		ObstacleActionQueue.Idle(ObstacleDelay);
		ObstacleActionQueue.Event(this, n"ObstacleStartMoving");
		ObstacleActionQueue.ReverseDuration(ObstacleMoveDuration, this, n"OnObstacleUpdate");
		ObstacleActionQueue.Event(this, n"ObstacleStopMoving");
		ObstacleActionQueue.Idle(ObstacleDelay);
	}

	UFUNCTION()
	void BP_Deactivate()
	{
		if (!HasControl())
			return;

		CrumbDeactivate();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDeactivate()
	{
		LocalDeactivate();
	}

	private void LocalDeactivate()
	{
		bIsActivated = false;
		SetActorTickEnabled(false);
		ActionQueue.Empty();
	}

	UFUNCTION()
	private void OnEnterKillTrigger(AHazePlayerCharacter Player)
	{
		if (ObstacleMoveAlpha < 0.1)
			return;

		Player.KillPlayer(FPlayerDeathDamageParams(ActorForwardVector, 1.0), DeathEffect);
	}

	UFUNCTION()
	private void StartMoving()
	{
		OnStartMoving.Broadcast();
		UIslandSeaSawWalkerPlatformEffectHandler::Trigger_OnStartMoving(this);
		UIslandSeaSawWalkerPlatformEffectHandler::Trigger_OnPlatformStartMoving(this);
	}

	UFUNCTION()
	private void StopMoving()
	{
		OnReachedDestination.Broadcast();
		UIslandSeaSawWalkerPlatformEffectHandler::Trigger_OnReachedDestination(this);
		UIslandSeaSawWalkerPlatformEffectHandler::Trigger_OnPlatformStopMoving(this);
	}

	UFUNCTION()
	private void OnUpdate(float Alpha)
	{
		float CurveValue = MoveCurve.GetFloatValue(Alpha);
		SetActorRelativeRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, CurveValue));
		MoveAlpha = Alpha;
	}

	UFUNCTION()
	private void ObstacleStartMoving()
	{
		UIslandSeaSawWalkerPlatformEffectHandler::Trigger_OnObstacleStartMoving(this);
	}

	UFUNCTION()
	private void ObstacleStopMoving()
	{
		UIslandSeaSawWalkerPlatformEffectHandler::Trigger_OnObstacleStopMoving(this);
	}

	UFUNCTION()
	private void OnObstacleUpdate(float Alpha)
	{
		float CurveValue = ObstacleMoveCurve.GetFloatValue(Alpha);
		ObstacleComp.SetRelativeLocation(Math::Lerp(FVector(0,-780,75), FVector(0,780,75), CurveValue));
		ObstacleMoveAlpha = Alpha;
		PrintToScreen("" +ObstacleMoveAlpha);
	}
}

UCLASS(Abstract)
class UIslandSeaSawWalkerPlatformEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachedDestination() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlatformStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlatformStopMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnObstacleStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnObstacleStopMoving() {}
}