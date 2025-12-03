class ASanctuaryBossHeartClaf : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike HeartBeatTimeLike;

	UPROPERTY(EditInstanceOnly)
	float Delay = 0.0;

	FVector InitialScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HeartBeatTimeLike.BindUpdate(this, n"HeartBeatTimeLikeUpdate");
		InitialScale = ActorScale3D;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
	}

	UFUNCTION()
	void CallHeartBeat()
	{
		Timer::SetTimer(this, n"PlayHeartBeat", Delay);
	}

	UFUNCTION()
	private void PlayHeartBeat()
	{
		HeartBeatTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void HeartBeatTimeLikeUpdate(float Alpha)
	{
		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::Sin(Time::GameTimeSeconds * 15.0) * Alpha;
		FF.RightMotor = Math::Sin(-Time::GameTimeSeconds* 15.0) * Alpha;
		ForceFeedback::PlayWorldForceFeedbackForFrame(FF, ActorLocation, 100000, 150000);
		SetActorScale3D(Math::Lerp(InitialScale, InitialScale * 1.1, Alpha));
	}
};