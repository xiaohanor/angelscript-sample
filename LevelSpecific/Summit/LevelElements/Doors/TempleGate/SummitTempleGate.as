event void FSummitTempleGateSignature();

class ASummitTempleGate : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovableComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LeftGate;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RightGate;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 1.0;

	UPROPERTY(EditAnywhere)
	bool bAutoReverse;
		
	UPROPERTY(EditAnywhere)
	float DelayDuration = 4;
	
	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere)
	bool bActivateWithAcid;
	
	UPROPERTY(EditAnywhere)
	bool bActivateWithTail;

	UPROPERTY(EditAnywhere)
	bool bDisableDefaultCollision;
	
	UPROPERTY(EditInstanceOnly)
	bool bMoveComponent;

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bIsRotating;

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bCanBeOpenedFromStart = true;
	
	UPROPERTY(EditAnywhere, Category = "Setup")
	FRotator RotationSpeed = FRotator(0,0,0);
	UPROPERTY(EditAnywhere, Category = "Setup")
	FRotator ReverseRotationSpeed = FRotator(0,0,0);
	
	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedGameTime;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedBobbingRotation;

	UPROPERTY()
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 1.25;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailResponseComp;
	default TailResponseComp.bShouldStopPlayer = false;

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	UPROPERTY()
	FSummitTempleGateSignature OnActivated;

	UPROPERTY()
	FSummitTempleGateSignature OnReachedDestination;
	
	UPROPERTY()
	FSummitTempleGateSignature OnHit;

	UPROPERTY()
	bool bIsPlaying;
	bool bIsDisabled;
	bool bIsPlayingForward;
	bool bWasSetToEndState;

	bool bHasBeenHitOnce = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = MovableComp.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = DestinationComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		TailResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");

		if(!bCanBeOpenedFromStart)
			TailResponseComp.bEnabled = false;
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if (!bActivateWithTail)
        	return;
		
		FSummitTempleGateOnHitByRollParams EventParams;
		EventParams.HitLocation = Params.HitLocation;
		EventParams.SpeedTowardsHit = Params.SpeedTowardsImpact;

		if(bHasBeenHitOnce)
		{
			USummitTempleGateEventHandler::Trigger_OnHitByRollOpened(this, EventParams);
			return;
		}
		else
			USummitTempleGateEventHandler::Trigger_OnHitByRollNotOpened(this, EventParams);
		
		OnHit.Broadcast();
		Start();
	}

	UFUNCTION()
	void Start()
	{
		if (bWasSetToEndState)
			return;

		if (bIsDisabled)
			return;

		USummitTempleGateEventHandler::Trigger_OnStartedOpening(this);

		MoveAnimation.Play();
		OnActivated.Broadcast();
		bIsPlaying = true;

		if (CameraShake == nullptr)
			return;

		Game::GetPlayer(EHazePlayer::Mio).PlayCameraShake(CameraShake, this, 1.0);
		Game::GetPlayer(EHazePlayer::Zoe).PlayCameraShake(CameraShake, this, 1.0);

		bHasBeenHitOnce = true;
	}

	UFUNCTION(BlueprintCallable)
	void MakeOpenable()
	{
		TailResponseComp.bEnabled = true;
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
		MoveAnimation.SetNewTime(2.75);
		MoveAnimation.Play();
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		if (bIsDisabled)
			return;
		
		LeftGate.RelativeRotation = Math::LerpShortestPath(FRotator(0,10,0), FRotator(0,70,0), Alpha);
		RightGate.RelativeRotation = Math::LerpShortestPath(FRotator(0,-10,0), FRotator(0,-70,0), Alpha);
	}

	UFUNCTION()
	void OnFinished()
	{
		if (bWasSetToEndState)
			return;

		USummitTempleGateEventHandler::Trigger_OnFinishedOpening(this);
		
		if (MoveAnimation.Value == 0)
			BP_OnReset();

		if(MoveAnimation.Value != 1.0)
			return;

		OnReachedDestination.Broadcast();
		BP_OnRecachedDestination();
	}

	UFUNCTION(BlueprintCallable)
	void ToggleRollingImpact(bool bToggleOn)
	{
		TailResponseComp.bEnabled = bToggleOn;
	}

	UFUNCTION()
	void DisableMovement() {
		bIsDisabled = true;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnRecachedDestination(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnReverse(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnReset(){}

}
