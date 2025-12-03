class ASanctuaryBossFinalPhaseGhostSpike : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent GhostRoot;

	UPROPERTY()
	FHazeTimeLike AppearTimeLike;
	default AppearTimeLike.UseSmoothCurveZeroToOne();
	default AppearTimeLike.Duration = 1.0;

	UPROPERTY()
	FHazeTimeLike DisappearTimeLike;
	default DisappearTimeLike.UseSmoothCurveOneToZero();
	default DisappearTimeLike.Duration = 1.0;

	UPROPERTY()
	FHazeFrameForceFeedback FrameForceFeedback;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AppearTimeLike.BindUpdate(this, n"AppearTimeLikeUpdate");

		DisappearTimeLike.BindUpdate(this, n"DisappearTimeLikeUpdate");
		DisappearTimeLike.BindFinished(this, n"DisappearTimeLikeFinished");

		Timer::SetTimer(this, n"Disappear", 5.0);

		AppearTimeLike.Play();
		Game::Mio.PlayWorldCameraShake(CameraShake, this, ActorLocation, 100.0, 200.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector Direction = (Game::Mio.ActorCenterLocation - ActorLocation).GetSafeNormal() * FVector(0.2, 0.2, 1.0);
		GhostRoot.SetWorldRotation(FRotator::MakeFromZ(Direction));

		ForceFeedback::PlayWorldForceFeedbackForFrame(FrameForceFeedback, ActorLocation, 100.0, 200.0, 1.0, EHazeSelectPlayer::Mio);
	}

	UFUNCTION()
	private void AppearTimeLikeUpdate(float CurrentValue)
	{
		GhostRoot.SetRelativeLocation(FVector::UpVector * Math::Lerp(-300.0, 0.0, CurrentValue));
	}

	UFUNCTION()
	private void Disappear()
	{
		DisappearTimeLike.Play();
	}

	UFUNCTION()
	private void DisappearTimeLikeUpdate(float CurrentValue)
	{
		GhostRoot.SetRelativeLocation(FVector::UpVector * Math::Lerp(-300.0, 0.0, CurrentValue));
		SetActorScale3D(FVector(CurrentValue));
	}

	UFUNCTION()
	private void DisappearTimeLikeFinished()
	{
		Game::Mio.StopCameraShakeByInstigator(this);
		DestroyActor();
	}
};