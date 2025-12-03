event void ATundraRiverSlidingRockEvent();

class ATundra_River_SlidingRock : ATundraRiverBoulder_DestructibleObject
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent TargetLocation;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UNiagaraComponent AmbientFallingDebris;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger Trigger;

	UPROPERTY()
	ATundraRiverSlidingRockEvent OnStartFalling;

	UPROPERTY()
	ATundraRiverSlidingRockEvent OnFinishedFalling;

	bool bHasBeenTriggered = false;

	FTransform StartTransform;
	FTransform EndTransform;

	UPROPERTY(EditInstanceOnly)
	float FallDuration = 2;

	UPROPERTY()
	FHazeTimeLike FallAnimation;
	default FallAnimation.Duration = 1;
	default FallAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default FallAnimation.Curve.AddDefaultKey(1.0, 1.0);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		Trigger.OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnter");
		StartTransform = GetActorTransform();
		EndTransform = TargetLocation.GetWorldTransform();

		if(FallDuration > 0)
			FallAnimation.PlayRate = 1/FallDuration;

		FallAnimation.BindUpdate(this, n"TL_FallAnimationUpdate");
		FallAnimation.BindFinished(this, n"TL_FallAnimationFinished");
	}

	UFUNCTION()
	private void TL_FallAnimationUpdate(float CurrentValue)
	{
		FVector LerpLocation = Math::Lerp(StartTransform.Location, EndTransform.Location, CurrentValue);
		FRotator LerpRotation = Math::LerpShortestPath(StartTransform.Rotator(), EndTransform.Rotator(), CurrentValue);
		SetActorLocationAndRotation(LerpLocation, LerpRotation);
	}

	UFUNCTION()
	private void TL_FallAnimationFinished()
	{
		OnFinishedFalling.Broadcast();
		UTundra_River_SlidingRock_EffectHandler::Trigger_ReachEnd(this);
	}

	UFUNCTION()
	private void HandlePlayerEnter(AHazePlayerCharacter Player)
	{
		if(!bHasBeenTriggered)
		{
			bHasBeenTriggered = true;
			OnStartFalling.Broadcast();
			StartFalling();
		}
	}

	UFUNCTION()
	private void StartFalling()
	{
		UTundra_River_SlidingRock_EffectHandler::Trigger_StartFalling(this);
		FallAnimation.PlayFromStart();
	}
};