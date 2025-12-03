class ASkylineBallBossSwipingCar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SwipeRoot;

	UPROPERTY(DefaultComponent, Attach = SwipeRoot)
	USceneComponent CarRoot;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike SwipeTimeLike;
	default SwipeTimeLike.UseSmoothCurveZeroToOne();
	default SwipeTimeLike.Duration = 1.5;

	UPROPERTY(EditAnywhere)
	float SwipeDegrees = 60.0;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike ExtendTimeLike;
	default ExtendTimeLike.UseSmoothCurveZeroToOne();
	default ExtendTimeLike.Duration = 0.5;

	UPROPERTY(EditAnywhere)
	float ExtendDistance = 500.0;
	FVector StartLocation;

	bool bAttacking;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SwipeTimeLike.BindUpdate(this, n"SwipeTimeLikeUpdate");
		SwipeTimeLike.BindFinished(this, n"SwipeTimeLikeFinished");
		ExtendTimeLike.BindUpdate(this, n"ExtendTimeLikeUpdate");
		ExtendTimeLike.BindFinished(this, n"ExtendTimeLikeFinished");

		SwipeRoot.SetRelativeRotation(FRotator(0.0, SwipeDegrees, 0.0));
	}

	UFUNCTION()
	void Activate()
	{
		SwipeTimeLike.Play();
		bAttacking = true;
	}

	UFUNCTION()
	private void ExtendTimeLikeUpdate(float CurrentValue)
	{
		CarRoot.SetRelativeLocation(Math::Lerp(StartLocation, StartLocation + FVector::ForwardVector * ExtendDistance, CurrentValue));
	}

	UFUNCTION()
	private void ExtendTimeLikeFinished()
	{
		if (SwipeTimeLike.IsReversed())
			SwipeTimeLike.Play();
		else
			SwipeTimeLike.Reverse();
	}

	UFUNCTION()
	private void SwipeTimeLikeUpdate(float CurrentValue)
	{
		SwipeRoot.SetRelativeRotation(FRotator(0.0, Math::Lerp(SwipeDegrees, -SwipeDegrees, CurrentValue), 0.0));
	}

	UFUNCTION()
	private void SwipeTimeLikeFinished()
	{
		//StartLocation = CarRoot.RelativeLocation;
		//ExtendTimeLike.PlayFromStart();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bAttacking)
		{
			CarRoot.AddRelativeLocation(FVector::ForwardVector * ExtendDistance * DeltaSeconds / SwipeTimeLike.Duration);
		}
	}
};