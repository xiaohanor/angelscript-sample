event void FSummitDrawBridgeSignature();

class ASummitDrawBridge : AHazeActor
{

	UPROPERTY()
	FSummitDrawBridgeSignature OnActivated;

	UPROPERTY()
	FSummitDrawBridgeSignature OnCompleted;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent BaseComp;

	UPROPERTY(DefaultComponent, Attach = BaseComp)
	USceneComponent BridgeTipRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;
	
	UPROPERTY()
	UNiagaraSystem Effect;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditInstanceOnly)
	ASummitDrawBridgeWheel WheelOne;
	
	UPROPERTY(EditInstanceOnly)
	ASummitDrawBridgeWheel WheelTwo;

	UPROPERTY()
	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 2;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = Root.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");
		MoveAnimation.SetPlayRate(1.0);

		EndingTransform = DestinationComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

	}

	UFUNCTION()
	void ActivateBridge()
	{	

		if (MoveAnimation.IsPlaying())
			return;

		MoveAnimation.PlayFromStart();
		OnActivated.Broadcast();
		BP_OnActivated();

		FSummitDrawBridgeOnBridgeStartMovingParams Params;
		Params.BridgeLocation = ActorLocation;
		USummitDrawBridgeEventHandler::Trigger_OnBridgeStartMoving(this, Params);

		if (WheelOne != nullptr)
		{
			WheelOne.ActivateWheel();
			USummitDrawBridgeWheelEventHandler::Trigger_OnWheelStartTurning(WheelOne);
		}

		if (WheelTwo != nullptr)
		{
			WheelTwo.ActivateWheel();
			USummitDrawBridgeWheelEventHandler::Trigger_OnWheelStartTurning(WheelTwo);
		}
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		SetActorLocationAndRotation(Math::Lerp(StartingPosition, EndingPosition, Alpha), FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
	}

	UFUNCTION()
	void OnFinished()
	{
		Game::GetPlayer(EHazePlayer::Mio).PlayCameraShake(CameraShake, this, 1.0);
		Game::GetPlayer(EHazePlayer::Zoe).PlayCameraShake(CameraShake, this, 1.0);

		OnCompleted.Broadcast();

		FSummitDrawBridgeOnBridgeFinishMovingParams Params;
		Params.BridgeLocation = ActorLocation;
		Params.BridgeTipLocation = BridgeTipRoot.WorldLocation;
		USummitDrawBridgeEventHandler::Trigger_OnBridgeFinishMoving(this, Params);

		if (WheelOne != nullptr)
		{
			WheelOne.DeactivateWheel();
			USummitDrawBridgeWheelEventHandler::Trigger_OnWheelStopTurning(WheelOne);
		}

		if (WheelTwo != nullptr)
		{
			WheelTwo.DeactivateWheel();
			USummitDrawBridgeWheelEventHandler::Trigger_OnWheelStopTurning(WheelTwo);
		}

	}

	UFUNCTION(BlueprintEvent)
	void BP_OnActivated() {}

}
