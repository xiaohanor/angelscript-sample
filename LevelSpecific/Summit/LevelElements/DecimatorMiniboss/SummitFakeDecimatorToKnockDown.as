event void FSummitFakeDecimatorToKnockDownSignature();

class ASummitFakeDecimatorToKnockDown: AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovableComp;

	UPROPERTY(DefaultComponent, Attach = MovableComp)
	UStaticMeshComponent TailHitMesh;

	UPROPERTY(DefaultComponent, Attach = TailHitMesh)
	UTeenDragonTailAttackResponseComponent TailResponseComp;
	
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 2.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	float ReversePlayRate = 0.1;

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	UPROPERTY()
	FSummitFakeDecimatorToKnockDownSignature OnActivated;

	UPROPERTY()
	FSummitFakeDecimatorToKnockDownSignature OnReachedDestination;
	
	UPROPERTY()
	FSummitFakeDecimatorToKnockDownSignature OnHit;

	UPROPERTY()
	FSummitFakeDecimatorToKnockDownSignature OnReset;

	bool bIsActivated;
	bool bIsDisabled;
	bool bMovingForward;
	bool bResetBroadcasted;

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

		TailResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");

	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		if (bIsDisabled)
			return;

		MoveAnimation.SetPlayRate(1);
		bIsActivated = true;
		OnActivated.Broadcast();
		BP_OnActivated();
		Start();

	}

	UFUNCTION()
	void Start()
	{
		if (bIsDisabled)
			return;

		bMovingForward = true;
		bResetBroadcasted = false;
		OnHit.Broadcast();
		MoveAnimation.Play();

		if (CameraShake != nullptr)
		{
			Game::GetPlayer(EHazePlayer::Mio).PlayCameraShake(CameraShake, this, 1.0);
			Game::GetPlayer(EHazePlayer::Zoe).PlayCameraShake(CameraShake, this, 1.0);
		}
		
	}

	UFUNCTION()
	void DisableTailActivator()
	{
		bIsDisabled = true;
		// MoveAnimation.Stop();
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{

		SetActorLocationAndRotation(Math::Lerp(StartingPosition, EndingPosition, Alpha), FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
	

		if (bResetBroadcasted)
			return;

		if (!bMovingForward && Alpha < 0.1)
		{
			bResetBroadcasted = true;
			OnReset.Broadcast();
		}
			


	}

	UFUNCTION()
	void OnFinished()
	{

		if (MoveAnimation.Value == 1)
		{
			if (CameraShake != nullptr)
			{
				Game::GetPlayer(EHazePlayer::Mio).PlayCameraShake(CameraShake, this, 1.0);
				Game::GetPlayer(EHazePlayer::Zoe).PlayCameraShake(CameraShake, this, 1.0);
			}

			// MoveAnimation.SetPlayRate(ReversePlayRate);
			// MoveAnimation.Reverse();
			// bMovingForward = false;
			OnReachedDestination.Broadcast();
			
		}
		else
		{
			// OnReset.Broadcast();
			bIsActivated = false;
			BP_OnDeactivated();
		}

	}

	UFUNCTION(BlueprintEvent)
	void BP_OnActivated(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnDeactivated(){}

}
