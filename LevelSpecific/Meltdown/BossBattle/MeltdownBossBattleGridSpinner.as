event void FonSpinnerFinished();

class AMeltdownBossBattleGridSpinner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent RotationActor;
	
	UPROPERTY(DefaultComponent)
	UBillboardComponent RightActor;

	UPROPERTY(DefaultComponent)
	UBillboardComponent LeftActor;

	FVector StartVector;
	FVector RightVector;
	FVector LeftVector;

	FRotator StartRotation;
	FRotator RightRotation;
	FRotator LeftRotation;

	FHazeTimeLike StartToRight;
	default StartToRight.Duration = 3;
	default StartToRight.UseSmoothCurveZeroToOne();

	FHazeTimeLike RightToLeft;
	default RightToLeft.Duration = 6;
	default RightToLeft.UseSmoothCurveZeroToOne();

	FHazeTimeLike LeftToStart;
	default LeftToStart.Duration = 3;
	default LeftToStart.UseSmoothCurveZeroToOne();

	UPROPERTY()
	FonSpinnerFinished SpinnerDone;

	UPROPERTY(EditAnywhere)
	AMeltdownBossPhaseOne Rader;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartVector = RotationActor.WorldLocation;
		RightVector = RightActor.WorldLocation;
		LeftVector = LeftActor.WorldLocation;

		StartRotation = FRotator(0,10, 0);
		RightRotation = FRotator(0,10,90);
		LeftRotation = FRotator(0,10,-90);

		StartToRight.BindUpdate(this, n"OnStartToRightUpdating");
		StartToRight.BindFinished(this, n"StartToRightFinished");

		RightToLeft.BindUpdate(this, n"OnLeftToRightUpdating");
		RightToLeft.BindFinished(this, n"OnRightToLeftFinished");

		LeftToStart.BindUpdate(this, n"OnRightToStartUpdating");
		LeftToStart.BindFinished(this, n"OnRightToStartFinished");
	}


	UFUNCTION(BlueprintCallable)
	void StartSpinner()
	{
		StartToRight.PlayFromStart();
	}


	UFUNCTION()
	private void OnStartToRightUpdating(float CurrentValue)
	{
	//	SetActorLocation(Math::Lerp(StartVector,RightVector,CurrentValue));

		SetActorRotation(Math::LerpShortestPath(StartRotation,RightRotation, CurrentValue));

		Rader.PlatformMoveIndex = 1;
		Rader.PlatformMoveAlpha = CurrentValue;
	}

	UFUNCTION()
	private void StartToRightFinished()
	{
		RightToLeft.PlayFromStart();
	}

	UFUNCTION()
	private void OnLeftToRightUpdating(float CurrentValue)
	{
	//	SetActorLocation(Math::Lerp(RightVector,LeftVector,CurrentValue));

		SetActorRotation(Math::LerpShortestPath(RightRotation,LeftRotation,CurrentValue));

		Rader.PlatformMoveIndex = 2;
		Rader.PlatformMoveAlpha = CurrentValue;
	}

	UFUNCTION()
	private void OnRightToLeftFinished()
	{
		LeftToStart.PlayFromStart();
	}

	UFUNCTION()
	private void OnRightToStartUpdating(float CurrentValue)
	{
	//	SetActorLocation(Math::Lerp(LeftVector,StartVector,CurrentValue));

		SetActorRotation(Math::LerpShortestPath(LeftRotation,StartRotation,CurrentValue));

		Rader.PlatformMoveIndex = 3;
		Rader.PlatformMoveAlpha = CurrentValue;
	}

	UFUNCTION()
	private void OnRightToStartFinished()
	{
		SpinnerDone.Broadcast();
	}

};