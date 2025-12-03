event void FSummitEggElevatorSignature();

class ASummitEggElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EndingPositionComp;

	UPROPERTY(DefaultComponent)
	USceneComponent MovableObject;

	UPROPERTY(EditAnywhere)
	ASummitEggHolder EggHolder;
	
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere)
	bool bOneTimeUse;

	UPROPERTY(EditAnywhere)
	bool bDoubleInteract;

	UPROPERTY(EditAnywhere)
	ASummitEggHolder SecondEggHolder;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 16.0;

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
	FSummitEggElevatorSignature OnMoving;

	UPROPERTY()
	FSummitEggElevatorSignature OnCompleted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = MovableObject.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = EndingPositionComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

		if (EggHolder != nullptr) 
		{
			if(EggHolder.bIsDoubleInteract)
			{
				EggHolder.OnBothEggsPlaced.AddUFunction(this, n"BothEggsPlaced");
			}
			else
			{
				EggHolder.OnEggPlaced.AddUFunction(this, n"EggIsPlaced");
				EggHolder.OnEggRemoved.AddUFunction(this, n"EggIsRemoved");
			}
		}

		if (SecondEggHolder != nullptr)
		{
			if(!SecondEggHolder.bIsDoubleInteract)
			{
				SecondEggHolder.OnEggPlaced.AddUFunction(this, n"SecondEggIsPlaced");
			}
		}

	}

	

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		bIsPlaying = true;

		// SetActorLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
		// SetActorRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));

	}

	
	UFUNCTION()
	void OnFinished()
	{
		bIsPlaying = false;

		// Game::Mio.PlayWorldCameraShake(CameraShake, this, ActorLocation, 1000, 4000);
		// Game::Zoe.PvlayWorldCameraShake(CameraShake, this, ActorLocation, 1000, 4000);

	}

	UFUNCTION()
	void EggIsPlaced()
	{
		// StartPlatformAnimation();
	}

	
	UFUNCTION()
	void SecondEggIsPlaced()
	{
		// StartPlatformAnimation();
	}

	
	UFUNCTION(NotBlueprintCallable)
	private void BothEggsPlaced()
	{
		OnMoving.Broadcast();
		UASummitEggElevatorEffectHandler::Trigger_LiftStarted(this);
		Timer::SetTimer(this, n"OnDelayBetweenMoves", 1);
		
	}

	UFUNCTION()
	void OnDelayBetweenMoves()
	{
		StartPlatformAnimation();
	}

	UFUNCTION()
	void StartPlatformAnimation()
	{
		
		Game::Mio.PlayWorldCameraShake(CameraShake, this, ActorLocation, 1000, 4000);
		Game::Zoe.PlayWorldCameraShake(CameraShake, this, ActorLocation, 1000, 4000);
		MoveAnimation.Play();
		BP_EggIsPlaced();
	}

	UFUNCTION()
	void EggIsRemoved()
	{
		if (bDoubleInteract)
			return;
		MoveAnimation.Reverse();
		BP_EggIsRemoved();
	}

	UFUNCTION()
	void DestroyPlatform()
	{
		UASummitEggElevatorEffectHandler::Trigger_LiftStopped(this);
		BP_PlatformDestroyed();
	}

	UFUNCTION(BlueprintEvent)
	void BP_EggIsPlaced() {}

	UFUNCTION(BlueprintEvent)
	void BP_EggIsRemoved() {}

	UFUNCTION(BlueprintEvent)
	void BP_PlatformDestroyed() {}

};

UCLASS(Abstract)
class UASummitEggElevatorEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LiftStarted() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void LiftStopped() {}

}