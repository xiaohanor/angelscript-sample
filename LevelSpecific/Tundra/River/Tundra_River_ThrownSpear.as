class ATundra_River_ThrownSpear : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent WiggleScene;

	UPROPERTY(DefaultComponent, Attach = WiggleScene)
	UStaticMeshComponent Spear;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent TargetLocation;

	FVector StartLocation;
	FVector EndLocation;

	bool bHasBeenTriggered = false;
	float Delay = 0;
	float Apex = 100;
	
	UPROPERTY()
	FHazeTimeLike ThrowAnimation;
	default ThrowAnimation.Duration = 1;
	default ThrowAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default ThrowAnimation.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY()
	FHazeTimeLike WiggleAnimation;
	default WiggleAnimation.Duration = 1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WiggleAnimation.BindUpdate(this, n"TL_WiggleAnimationUpdate");
		ThrowAnimation.BindUpdate(this, n"TL_ThrowAnimationUpdate");
		ThrowAnimation.BindFinished(this, n"TL_ThrowAnimaionFinished");
		StartLocation = GetActorLocation();
		EndLocation = TargetLocation.GetWorldLocation();
	}

	UFUNCTION()
	private void TL_WiggleAnimationUpdate(float CurrentValue)
	{
	}

	UFUNCTION()
	private void TL_ThrowAnimationUpdate(float CurrentValue)
	{
		FVector NewLocation = Math::Lerp(StartLocation, EndLocation, CurrentValue);
		FVector CurrentLocation = GetActorLocation();
		
		FRotator LookAt = FRotator::MakeFromXZ((NewLocation - CurrentLocation).GetSafeNormal(SMALL_NUMBER, GetActorForwardVector()), FVector::UpVector);

		SetActorRotation(LookAt);
		SetActorLocation(NewLocation);
		
	}

	UFUNCTION()
	private void TL_ThrowAnimaionFinished()
	{
		SetActorLocation(EndLocation);
	}

	UFUNCTION()
	void TriggerSpears(float DelayBeforeTrigger)
	{
		if(!bHasBeenTriggered)
		{
			bHasBeenTriggered = true;
			if(DelayBeforeTrigger > 0)
			{
				Delay = DelayBeforeTrigger;
			}

			else
			{
				ThrowAnimation.PlayFromStart();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Delay >  0)
		{
			Delay -= DeltaSeconds;
			if(Delay <= 0)
			{
				ThrowAnimation.PlayFromStart();
			}
		}
	}
};