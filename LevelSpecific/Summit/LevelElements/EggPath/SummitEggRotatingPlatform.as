event void FSummitEggRotatingPlatformSignature();

class ASummitEggRotatingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EndingPositionComp;

	UPROPERTY(DefaultComponent)
	USceneComponent MovableObject;

	UPROPERTY(DefaultComponent, Attach = MovableObject)
	USceneComponent Pivot;

	FRotator RotationRate = FRotator(0,-15, 0); 

	UPROPERTY(EditAnywhere)
	ASummitEggHolder EggHolder;
	
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 1.0;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	bool bIsPlaying;

	UPROPERTY()
	FSummitEggRotatingPlatformSignature OnMoving;

	UPROPERTY(EditAnywhere)
	AKineticRotatingActor RotatingActorRef;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = Pivot.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = EndingPositionComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		EggHolder.OnEggPlaced.AddUFunction(this, n"EggIsPlaced");
		EggHolder.OnEggRemoved.AddUFunction(this, n"EggIsRemoved");

		if (RotatingActorRef != nullptr)
			RotatingActorRef.PauseMovement(this);

	}

	UFUNCTION()
	void EggIsPlaced()
	{
		// RotatingMovement.RotationRate = RotationRate;
		// RotatingActorRef.ActivateForward();
		RotatingActorRef.UnpauseMovement(this);

	}
	
	UFUNCTION()
	void EggIsRemoved()
	{
		// RotatingMovement.RotationRate = FRotator(0, 0, 0);
		RotatingActorRef.PauseMovement(this);
		// RotatingActorRef.ActivateForward();
	}

	UFUNCTION()
	void StartPlatformAnimation()
	{
		OnMoving.Broadcast();
		MoveAnimation.Play();
		BP_EggIsPlaced();
	}

	
	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		bIsPlaying = true;

		Pivot.SetWorldLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
		Pivot.SetWorldRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
	}

	UFUNCTION()
	void OnFinished()
	{
		bIsPlaying = false;
		
	}

	UFUNCTION(BlueprintEvent)
	void BP_EggIsPlaced() {}

	UFUNCTION(BlueprintEvent)
	void BP_EggIsRemoved() {}

};