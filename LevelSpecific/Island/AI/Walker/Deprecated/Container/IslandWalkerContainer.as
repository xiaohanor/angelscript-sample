event void IslandWalkerContainerOpenedSignature();

class AIslandWalkerContainer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent TargetLocation;

	UPROPERTY(DefaultComponent)
	USceneComponent Joint0;

	UPROPERTY(DefaultComponent)
	USceneComponent Joint1;

	UPROPERTY(DefaultComponent)
	USceneComponent Joint2;

	UPROPERTY(DefaultComponent)
	USceneComponent Joint3;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent RegisterComp;

	UPROPERTY()
	IslandWalkerContainerOpenedSignature OnOpened;

	FVector StartLocation;
	FVector DropLocation;

	FRotator Joint0TargetRot = FRotator(-90, 0, 0);
	FRotator Joint1TargetRot = FRotator(90, 0, 0);
	FRotator Joint2TargetRot = FRotator(0, 0, 90);
	FRotator Joint3TargetRot = FRotator(0, 0, -90);

	FHazeAcceleratedRotator Joint0Aacc;
	FHazeAcceleratedRotator Joint1Aacc;
	FHazeAcceleratedRotator Joint2Aacc;
	FHazeAcceleratedRotator Joint3Aacc;

	float MoveDuration = 0.75;
	float OpenDelay = 1;
	float OpenDuration = 4;

	float StartTime;
	float OpenTime;

	float MoveAlpha;
	float MoveSpeed = 2;
	FHazeAcceleratedFloat SpeedAcc;

	UPROPERTY()
	TSubclassOf<AAIIslandWalker> SpawnClass;

	UPROPERTY(BlueprintReadOnly, NotVisible)
	AAIIslandWalker Walker;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> LandCameraShake;
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> OpenCameraShake;
	UPROPERTY()
	UForceFeedbackEffect LandForceFeedback;
	UPROPERTY()
	UForceFeedbackEffect OpenForceFeedback;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Joint0Aacc.Value = Joint0.RelativeRotation;
		Joint1Aacc.Value = Joint1.RelativeRotation;
		Joint2Aacc.Value = Joint2.RelativeRotation;
		Joint3Aacc.Value = Joint3.RelativeRotation;
		StartLocation = ActorLocation;
		DropLocation = TargetLocation.WorldLocation;

		Walker = SpawnActor(SpawnClass, ActorLocation, ActorRotation, NAME_None, true, Level);
		Walker.MakeNetworked(this, n"Walker");
		Walker.PhaseComp.Phase = EIslandWalkerPhase::Intro;
		FinishSpawningActor(Walker);
		Walker.BlockCapabilities(BasicAITags::Behaviour, this);
		Walker.BlockCapabilities(CapabilityTags::Movement, this);
		Walker.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Walker.AttachToActor(this);
		Walker.PowerDown();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(StartTime == 0)
			return;

		if(MoveAlpha < 1)
		{
			Move(DeltaSeconds);
			return;
		}

		if(Time::GetGameTimeSince(OpenTime) < OpenDelay)
			return;

		if(Time::GetGameTimeSince(OpenTime) < OpenDelay + OpenDuration)
		{
			Open(DeltaSeconds);
			return;
		}

		for(AHazePlayerCharacter Player: Game::Players)
		{
			Player.PlayCameraShake(OpenCameraShake, this);
			Player.PlayForceFeedback(OpenForceFeedback, false, false, this);
		}

		OnCompletedOpening();
	}

	void OnCompletedMove()
	{
		OpenTime = Time::GameTimeSeconds;
		UIslandWalkerContainerEffectHandler::Trigger_OnLand(this);
		Walker.DetachRootComponentFromParent(true);

		for(AHazePlayerCharacter Player: Game::Players)
		{
			Player.PlayCameraShake(LandCameraShake, this);
			Player.PlayForceFeedback(LandForceFeedback, false, false, this);
		}
	}

	void OnCompletedOpening()
	{
		OnOpened.Broadcast();
		Walker.UnblockCapabilities(BasicAITags::Behaviour, this);
		Walker.UnblockCapabilities(CapabilityTags::Movement, this);
		Walker.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Walker.PowerUp();
		if (Walker.PhaseComp.Phase == EIslandWalkerPhase::Intro)
			Walker.PhaseComp.SetPhase(EIslandWalkerPhase::Walking);
		StartTime = 0;
	}

	UFUNCTION(BlueprintCallable)
	void Start()
	{
		StartTime = Time::GameTimeSeconds;
		StartLocation = ActorLocation;
	}

	private void Move(float DeltaTime)
	{
		SpeedAcc.AccelerateTo(MoveSpeed, 1, DeltaTime);
		MoveAlpha = Math::Clamp(MoveAlpha + DeltaTime * SpeedAcc.Value, 0.0, 1.0);
		ActorLocation = Math::Lerp(StartLocation, DropLocation, MoveAlpha);
		if(MoveAlpha > 1.0 - SMALL_NUMBER)
			OnCompletedMove();
	}

	private void Open(float DeltaTime)
	{
		Joint0Aacc.AccelerateTo(Joint0TargetRot, OpenDuration, DeltaTime);
		Joint0.RelativeRotation = Joint0Aacc.Value;

		Joint1Aacc.AccelerateTo(Joint1TargetRot, OpenDuration, DeltaTime);
		Joint1.RelativeRotation = Joint1Aacc.Value;

		Joint2Aacc.AccelerateTo(Joint2TargetRot, OpenDuration, DeltaTime);
		Joint2.RelativeRotation = Joint2Aacc.Value;

		Joint3Aacc.AccelerateTo(Joint3TargetRot, OpenDuration, DeltaTime);
		Joint3.RelativeRotation = Joint3Aacc.Value;
	}
}