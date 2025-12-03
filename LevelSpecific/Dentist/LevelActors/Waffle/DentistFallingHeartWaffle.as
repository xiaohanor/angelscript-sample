enum EDentistFallingHeartWaffleState
{
	Idle,
	Impacted,
	Falling,
	Spawning,
};

UCLASS(Abstract)
class ADentistFallingHeartWaffle : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent WaffleRoot;

	UPROPERTY(DefaultComponent, Attach = WaffleRoot)
	USceneComponent WaffleRotateRoot;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComponent;

	UPROPERTY(DefaultComponent)
	UDentistToothMovementResponseComponent MovementResponseComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY()
	FHazeTimeLike SpawnTimeLike;
	default SpawnTimeLike.UseSmoothCurveZeroToOne();
	default TiltTimeLike.Duration = 1.0;

	FHazeTimeLike TiltTimeLike;
	default TiltTimeLike.UseSmoothCurveZeroToOne();
	default TiltTimeLike.Duration = 0.5;

	UPROPERTY()
	float FallDelay = 2.0;

	UPROPERTY()
	float RespawnDelay = 6.0;

	EDentistFallingHeartWaffleState State = EDentistFallingHeartWaffleState::Idle;
	float FallSpeed = 0.0;
	float ShakeIntensity = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovementImpactCallbackComponent.OnGroundImpactedByPlayer.AddUFunction(this, n"HandlePlayerImpact");
		TiltTimeLike.BindUpdate(this, n"TiltTimeLikeUpdate");
		SpawnTimeLike.BindUpdate(this, n"SpawnTimeLikeUpdate");
		SpawnTimeLike.BindFinished(this, n"SpawnTimeLikeFinished");
		MovementResponseComp.OnGroundPoundedOn.AddUFunction(this, n"OnGroundPound");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FHazeFrameForceFeedback FrameFF;

		switch(State)
		{
			case EDentistFallingHeartWaffleState::Idle:
				SetActorTickEnabled(false);
				break;

			case EDentistFallingHeartWaffleState::Impacted:
				WaffleRotateRoot.SetRelativeRotation(FRotator(1.0 * ShakeIntensity * (Math::Sin(Time::GameTimeSeconds * 20.0) - 0.5)));

				FrameFF.LeftMotor = Math::Abs(Math::Sin(Time::GameTimeSeconds * 20.0) * 0.25);
				ForceFeedback::PlayWorldForceFeedbackForFrame(FrameFF, WaffleRotateRoot.WorldLocation, 300.0, 600.0);
				break;

			case EDentistFallingHeartWaffleState::Falling:
				FallSpeed += 1000.0 * DeltaSeconds;
				WaffleRoot.AddRelativeLocation(FVector(0.0, 0.3, -1.0) * DeltaSeconds * FallSpeed);
				WaffleRotateRoot.AddRelativeRotation(FRotator(0.0, 0.0, 60.0 * DeltaSeconds));
				break;

			case EDentistFallingHeartWaffleState::Spawning:
				break;

		}
	}

	UFUNCTION()
	private void OnGroundPound(AHazePlayerCharacter GroundPoundPlayer, FHitResult Impact)
	{
		Fall();
	}

	UFUNCTION()
	private void HandlePlayerImpact(AHazePlayerCharacter Player)
	{
		BP_Audio_OnImpacted();

		if (State == EDentistFallingHeartWaffleState::Impacted || State == EDentistFallingHeartWaffleState::Falling)
			return;

		TiltTimeLike.PlayFromStart();
		Timer::SetTimer(this, n"Fall", FallDelay);

		State = EDentistFallingHeartWaffleState::Impacted;
		SetActorTickEnabled(true);

		BP_Audio_OnStartWiggling(Player);
	}

	UFUNCTION()
	void Fall()
	{
		if (State == EDentistFallingHeartWaffleState::Falling)
			return;
		
		Timer::SetTimer(this, n"Respawn", RespawnDelay);
		
		State = EDentistFallingHeartWaffleState::Falling;
		SetActorTickEnabled(true);

		BP_WaffleFall();
	}

	UFUNCTION()
	private void TiltTimeLikeUpdate(float CurrentValue)
	{
		WaffleRoot.SetRelativeRotation(FRotator(0.0, 0.0, 8.0 * CurrentValue));
		ShakeIntensity = CurrentValue;
	}

	UFUNCTION()
	private void SpawnTimeLikeUpdate(float CurrentValue)
	{
		WaffleRoot.SetRelativeScale3D(FVector::OneVector * CurrentValue);
	}

	UFUNCTION()
	private void SpawnTimeLikeFinished()
	{
		if(State == EDentistFallingHeartWaffleState::Spawning)
		{
			SetActorTickEnabled(false);
			State = EDentistFallingHeartWaffleState::Idle;
		}
	}

	UFUNCTION()
	private void Respawn()
	{
		WaffleRoot.SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);
		WaffleRotateRoot.SetRelativeRotation(FRotator::ZeroRotator);
		FallSpeed = 0.0;
		ShakeIntensity = 0.0;

		SpawnTimeLike.PlayFromStart();
		State = EDentistFallingHeartWaffleState::Spawning;

		BP_WaffleRespawn();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_WaffleFall(){}

	UFUNCTION(BlueprintEvent)
	private void BP_WaffleRespawn(){}

	/**
	 * AUDIO
	 */

	UFUNCTION(BlueprintEvent, Category = "Audio")
	private void BP_Audio_OnImpacted() {}

	UFUNCTION(BlueprintEvent, Category = "Audio")
	private void BP_Audio_OnStartWiggling(AHazePlayerCharacter Player) {}

	UFUNCTION(BlueprintEvent, Category = "Audio")
	private void BP_Audio_OnFall() {}

	UFUNCTION(BlueprintEvent, Category = "Audio")
	private void BP_Audio_OnStartRespawning() {}

	UFUNCTION(BlueprintEvent, Category = "Audio")
	private void BP_Audio_OnFinishedRespawning() {}
};