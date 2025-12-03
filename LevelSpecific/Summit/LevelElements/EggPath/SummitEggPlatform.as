event void FSummitEggPlatformSignature();

class ASummitEggPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EndingPositionComp;

	UPROPERTY(DefaultComponent)
	USceneComponent MovableObject;

	UPROPERTY(DefaultComponent, Attach = MovableObject)
	USceneComponent Pivot;

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
	FSummitEggPlatformSignature OnMoving;

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

		Pivot.SetWorldLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
		Pivot.SetWorldRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));

	}

	
	UFUNCTION()
	void OnFinished()
	{
		bIsPlaying = false;

		if (MoveAnimation.IsReversed())
		{
			UASummitEggPlatformEffectHandler::Trigger_WingFullyDown(this);
			BP_SetPlatformWalkable(false);
		}
		else
		{
			UASummitEggPlatformEffectHandler::Trigger_WingFullyUp(this);
			BP_SetPlatformWalkable(true);
		}
		
		// Game::Mio.PlayWorldCameraShake(CameraShake, this, ActorLocation, 1000, 4000);
		// Game::Zoe.PvlayWorldCameraShake(CameraShake, this, ActorLocation, 1000, 4000);

	}

	UFUNCTION(BlueprintEvent)
	void BP_SetPlatformWalkable(bool bWalkable)
	{

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
		Game::Mio.PlayWorldCameraShake(CameraShake, this, ActorLocation, 1000, 4000);
		Game::Zoe.PlayWorldCameraShake(CameraShake, this, ActorLocation, 1000, 4000);
		MoveAnimation.Play();
		UASummitEggPlatformEffectHandler::Trigger_WingUp(this);
		BP_EggIsPlaced();
	}

	UFUNCTION()
	void EggIsRemoved()
	{
		if (bDoubleInteract)
			return;
		MoveAnimation.Reverse();
		UASummitEggPlatformEffectHandler::Trigger_WingDown(this);
		BP_EggIsRemoved();
	}




	UFUNCTION(BlueprintEvent)
	void BP_EggIsPlaced() {}

	UFUNCTION(BlueprintEvent)
	void BP_EggIsRemoved() {}
};

UCLASS(Abstract)
class UASummitEggPlatformEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WingUp() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WingDown() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WingFullyUp() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void WingFullyDown() {}

}