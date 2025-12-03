event void FSummitTailFallingPillarSignature();

class ASummitTailFallingPillar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovableComp;

	UPROPERTY(DefaultComponent)
	UBoxComponent KnockCollision;
		
	UPROPERTY(EditAnywhere)
	float DelayDuration = 0.2;
	
	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 3.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailResponseComp;

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	UPROPERTY()
	FSummitTailFallingPillarSignature OnActivated;

	UPROPERTY()
	FSummitTailFallingPillarSignature OnReachedDestination;
	
	UPROPERTY()
	FSummitTailFallingPillarSignature OnHit;

	UPROPERTY()
	FSummitTailFallingPillarSignature OnReset;
	
	UPROPERTY()
	FHazeTimeLike  DelayAnimation;
	default DelayAnimation.Duration = 1.0;
	default DelayAnimation.UseSmoothCurveZeroToOne();

	UPROPERTY()
	bool bIsPlaying;
	bool bIsDisabled;
	bool bIsPlayingForward;
	bool bWasSetToEndState;

	float PlayRate;
	float TargetPlayRate = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = MovableComp.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = DestinationComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		MoveAnimation.SetPlayRate(1.0);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		if (DelayDuration == 0)
			DelayDuration = SMALL_NUMBER;

		DelayAnimation.SetPlayRate(1.0 / DelayDuration);

		//NO LONGER APPLICABLE - JOHN
		// TailResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		KnockCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");

		PlayRate = TargetPlayRate;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		PlayRate = Math::FInterpConstantTo(PlayRate, TargetPlayRate, DeltaSeconds, TargetPlayRate / 4.0);
		MoveAnimation.SetPlayRate(PlayRate);
	}

	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{	

		if (!MoveAnimation.IsPlaying())
			return;

		auto FallingPillar = Cast<ASummitTailFallingPillar>(OtherActor);

		if (FallingPillar == nullptr)
			return;

		FallingPillar.Start();
		FallingPillar.PlayRate = 0.0;

		PlayRate = TargetPlayRate;

		BP_OnActivated();
	}

	//NO LONGER APPLICABLE - JOHN
	// UFUNCTION()
	// private void OnHitByRoll(FRollParams Params)
	// {
	// 	Start();
	// }

	UFUNCTION()
	void Start()
	{
		if (bWasSetToEndState)
			return;

		if (bIsDisabled)
			return;

		OnHit.Broadcast();

		Game::GetPlayer(EHazePlayer::Mio).PlayCameraShake(CameraShake, this, 1.0);
		Game::GetPlayer(EHazePlayer::Zoe).PlayCameraShake(CameraShake, this, 1.0);

		MoveAnimation.Play();
		OnActivated.Broadcast();
		BP_OnActivated();
		bIsPlaying = true;
	}

	UFUNCTION()
	void Reverse()
	{
		if (bIsDisabled)
			return;

		MoveAnimation.Reverse();
		bIsPlaying = false;
		BP_OnReverse();

	}

	UFUNCTION()
	void SetEndState()
	{
		bWasSetToEndState = true;
		MoveAnimation.SetNewTime(2.0);
		MoveAnimation.Play();
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		if (bIsDisabled)
			return;

		SetActorLocationAndRotation(Math::Lerp(StartingPosition, EndingPosition, Alpha), FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
	}

	UFUNCTION()
	void OnFinished()
	{
		if (bWasSetToEndState)
			return;

		OnReachedDestination.Broadcast();
		BP_OnRecachedDestination();
		
		if (CameraShake == nullptr)
			return;

		Game::GetPlayer(EHazePlayer::Mio).PlayCameraShake(CameraShake, this, 1.0);
		Game::GetPlayer(EHazePlayer::Zoe).PlayCameraShake(CameraShake, this, 1.0);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnActivated(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnRecachedDestination(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnReverse(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnReset(){}

}
