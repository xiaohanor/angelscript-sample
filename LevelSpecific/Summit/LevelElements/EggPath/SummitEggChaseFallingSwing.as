event void FASummitEggChaseFallingSwingSignature();

class ASummitEggChaseFallingSwing : AHazeActor
{
UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EndingPositionComp;

	UPROPERTY(DefaultComponent)
	USceneComponent MovableObject;

	UPROPERTY(DefaultComponent)
	USwingPointComponent SwingPointComp;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	UNiagaraSystem ExplosionEffect;

	UPROPERTY(EditAnywhere)
	float DelayDuration = 1.0;

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 3.0;

	UPROPERTY()
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger TriggerRef;
	
	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	UPROPERTY()
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	bool bIsPlaying;

	UPROPERTY()
	FASummitEggChaseFallingSwingSignature OnMoving;

	UPROPERTY()
	FASummitEggChaseFallingSwingSignature OnCompleted;

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

		if (DelayDuration == 0)
			DelayDuration = SMALL_NUMBER;

		if(TriggerRef != nullptr)
			TriggerRef.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");

	}

	UFUNCTION()
	void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if (bIsPlaying)
			return;

		StartFalling();
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		

		SetActorLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
		SetActorRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));

	}

	
	UFUNCTION()
	void OnFinished()
	{
		bIsPlaying = false;
		SwingPointComp.Disable(this);
		OnCompleted.Broadcast();
		BP_HandleOnCompleted();

		UASummitEggChaseFallingSwingEffectHandler::Trigger_OnFallCompleted(this);

		if (CameraShake == nullptr)
			return;

		Game::Mio.PlayWorldCameraShake(CameraShake, this, ActorLocation, 1000, 4000);
		Game::Zoe.PlayWorldCameraShake(CameraShake, this, ActorLocation, 1000, 4000);

		

	}

	UFUNCTION()
	void StartFalling()
	{
		Timer::SetTimer(this, n"StartPlatformAnimation", DelayDuration);
	}

	UFUNCTION()
	void StartPlatformAnimation()
	{
		bIsPlaying = true;
		OnMoving.Broadcast();
		MoveAnimation.Play();
		UASummitEggChaseFallingSwingEffectHandler::Trigger_OnStartFall(this);
		
	}

	UFUNCTION(BlueprintEvent)
	void BP_HandleOnCompleted(){}

};

UCLASS(Abstract)
class UASummitEggChaseFallingSwingEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartFall() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFallCompleted() {}

}