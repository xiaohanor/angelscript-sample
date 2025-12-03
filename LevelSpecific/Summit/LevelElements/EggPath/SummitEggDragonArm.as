event void FSummitEggDragonArmSignature();

class ASummitEggDragonArm : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EndingPositionComp;

	UPROPERTY(DefaultComponent)
	USceneComponent MovableObject;

	UPROPERTY(DefaultComponent, Attach = MovableObject)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UStaticMeshComponent StaticMesh;

	UPROPERTY(EditAnywhere)
	ASummitEggHolder EggHolder;
	
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShakeCompleted;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY(EditAnywhere)
	bool bOneTimeUse;

	UPROPERTY(EditAnywhere)
	bool bDoubleInteract = true;

	UPROPERTY(EditAnywhere)
	ASummitEggHolder SecondEggHolder;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 3.0;

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
	FSummitEggDragonArmSignature OnMoving;

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

		if (EggHolder != nullptr) 
		{
			if(EggHolder.bIsDoubleInteract)
			{
				EggHolder.OnBothEggsPlaced.AddUFunction(this, n"BothEggsPlaced");
			}
			else
			{
				EggHolder.OnEggPlaced.AddUFunction(this, n"EggIsPlaced");
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

		Pivot.SetWorldLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
		Pivot.SetWorldRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));

	}

	
	UFUNCTION()
	void OnFinished()
	{
		bIsPlaying = false;

		UASummitEggDragonArmEffectHandler::Trigger_OnEndMove(this);

		if (CameraShakeCompleted != nullptr)
		{
			Game::Mio.PlayWorldCameraShake(CameraShakeCompleted, this, ActorLocation, 1000, 4000);
			Game::Zoe.PlayWorldCameraShake(CameraShakeCompleted, this, ActorLocation, 1000, 4000);
		}

	}

	UFUNCTION()
	void EggIsPlaced()
	{
		StartPlatformAnimation();
	}

	
	UFUNCTION()
	void SecondEggIsPlaced()
	{
		StartPlatformAnimation();
	}

	
	UFUNCTION(NotBlueprintCallable)
	private void BothEggsPlaced()
	{
		StartPlatformAnimation();
	}

	UFUNCTION()
	void StartPlatformAnimation()
	{
		OnMoving.Broadcast();
		
		MoveAnimation.Play();
		UASummitEggDragonArmEffectHandler::Trigger_OnStartMove(this);
		BP_EggIsPlaced();

		if (CameraShake != nullptr)
		{
			Game::Mio.PlayWorldCameraShake(CameraShake, this, ActorLocation, 1000, 4000);
			Game::Zoe.PlayWorldCameraShake(CameraShake, this, ActorLocation, 1000, 4000);
		}

		if(ForceFeedback == nullptr)
			return;

		Game::GetMio().PlayForceFeedback(ForceFeedback, false, false, this);
		Game::GetZoe().PlayForceFeedback(ForceFeedback, false, false, this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_EggIsPlaced() {}

	UFUNCTION(BlueprintEvent)
	void BP_EggIsRemoved() {}
};

UCLASS(Abstract)
class UASummitEggDragonArmEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMove() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEndMove() {}

}