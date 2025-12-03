event void FSummitMagicalRollPlatformSignature();

class ASummitMagicalRollPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovableComp;
	
	UPROPERTY(DefaultComponent, Attach = MovableComp)
	USceneComponent BobComp;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 0.75;
	
	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere, Category = "Setup")
	float BobHeight = 25.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	float BobSpeed = 4.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	float BobOffset = 0.0;
	
	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedGameTime;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedBobbingRotation;

	UPROPERTY()
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	FTransform StartingTransform;

	UPROPERTY()
	FQuat StartingRotation;

	UPROPERTY()
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	UPROPERTY()
	FSummitMagicalRollPlatformSignature OnActivated;

	UPROPERTY()
	FSummitMagicalRollPlatformSignature OnReachedDestination;

	UPROPERTY()
	bool bIsPlaying;
	bool bIsDisabled;

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

		if(HasControl())
		{
			SyncedGameTime.Value = Time::GameTimeSeconds;
			SyncedBobbingRotation.Value = BobComp.RelativeRotation;
		}
	}

	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

		if(HasControl())
			SyncedGameTime.Value = Time::GameTimeSeconds;

		if(bIsPlaying)
			return;

		// BobComp.SetRelativeLocation(FVector::UpVector * Math::Sin((SyncedGameTime.Value * BobSpeed + BobOffset)) * BobHeight);
	}


	UFUNCTION()
	void Start()
	{
		if (bIsDisabled)
			return;

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
	void OnUpdate(float Alpha)
	{
		if (bIsDisabled)
			return;

		MovableComp.SetWorldLocationAndRotation(Math::Lerp(StartingPosition, EndingPosition, Alpha), FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
	}

	UFUNCTION()
	void OnFinished()
	{

		if (MoveAnimation.Value == 0)
			BP_OnReset();

		if(MoveAnimation.Value != 1.0)
			return;

		OnReachedDestination.Broadcast();
		BP_OnRecachedDestination();

		if (CameraShake == nullptr)
			return;

		Game::GetPlayer(EHazePlayer::Mio).PlayCameraShake(CameraShake, this, 1.0);
		Game::GetPlayer(EHazePlayer::Zoe).PlayCameraShake(CameraShake, this, 1.0);
	}


	UFUNCTION()
	void DisableMovement() {
		bIsDisabled = true;
	}
	
	UFUNCTION(BlueprintEvent)
	void BP_OnImpact(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnActivated(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnRecachedDestination(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnReverse(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnReset(){}

}
