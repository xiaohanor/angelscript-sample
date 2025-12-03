event void FIslandShieldedElevatorSignature();

class AIslandShieldedElevator : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovableComp;

	UPROPERTY(DefaultComponent, Attach = MovableComp)
	UCameraShakeForceFeedbackComponent CamShakeFFComp;

	UPROPERTY(DefaultComponent, Attach = MovableComp)
	UPlayerWorldRumbleTrigger MovingFFTrigger;

	#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
	#endif


	UPROPERTY(EditAnywhere)
	float AnimationDuration = 1.0;
	
	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 27.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	UPROPERTY()
	FIslandShieldedElevatorSignature OnElevatorMoving;

	UPROPERTY()
	FIslandShieldedElevatorSignature OnElevatorStopped;

	UPROPERTY()
	bool bIsPlaying;
	bool bMovingBack;

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

		MovingFFTrigger.DisableTrigger(this);

	}

	UFUNCTION()
	void Start()
	{
		MoveAnimation.Play();
		OnElevatorMoving.Broadcast();
		UIslandShieldedElevatorEffectHandler::Trigger_OnStartMoving(this);

		CamShakeFFComp.ActivateCameraShakeAndForceFeedback();
		MovingFFTrigger.EnableTrigger(this);

		// if (CameraShake == nullptr)
		// 	return;

		// Game::GetPlayer(EHazePlayer::Mio).PlayCameraShake(CameraShake, this, 0.5);
		// Game::GetPlayer(EHazePlayer::Zoe).PlayCameraShake(CameraShake, this, 0.5);
	}

	UFUNCTION()
	void Reverse()
	{
		MoveAnimation.Reverse();

	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		bIsPlaying = true;
		
		SetActorLocationAndRotation(Math::Lerp(StartingPosition, EndingPosition, Alpha), FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
	}

	
	UFUNCTION()
	void OnFinished()
	{
		bIsPlaying = false;
		UIslandShieldedElevatorEffectHandler::Trigger_OnStopMoving(this);

		if(MoveAnimation.Value != 1.0)
			return;

		OnElevatorStopped.Broadcast();

		CamShakeFFComp.ActivateCameraShakeAndForceFeedback();
		MovingFFTrigger.DisableTrigger(this);
		
		// if (CameraShake == nullptr)
		// 	return;

		// Game::GetPlayer(EHazePlayer::Mio).PlayCameraShake(CameraShake, this, 1.0);
		// Game::GetPlayer(EHazePlayer::Zoe).PlayCameraShake(CameraShake, this, 1.0);

	}

}

UCLASS(Abstract)
class UIslandShieldedElevatorEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStopMoving() {}
}