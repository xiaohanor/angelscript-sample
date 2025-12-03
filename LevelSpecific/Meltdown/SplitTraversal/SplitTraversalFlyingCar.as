class ASplitTraversalFlyingCar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CarRoot;

	UPROPERTY(DefaultComponent, Attach = CarRoot)
	UDeathTriggerComponent DeathTriggerComp;

	UPROPERTY(EditAnywhere)
	float Interval = 5.0;

	UPROPERTY(EditAnywhere)
	float Offset = 0.0;

	UPROPERTY(EditAnywhere)
	float Speed = 11200.0;

	bool bActive = false;

	FVector ActorStartLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActorStartLocation = ActorLocation;
	}

	UFUNCTION()
	void Activate()
	{
		if (Offset > 0.0)
			Timer::SetTimer(this, n"DelayedActivate", Offset);
		else
			DelayedActivate();

		SetActorLocation(ActorStartLocation);
	}

	UFUNCTION()
	private void DelayedActivate()
	{
		bActive = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bActive)
			return;

		CarRoot.AddRelativeLocation(FVector::ForwardVector * Speed * DeltaSeconds);

		if (CarRoot.RelativeLocation.X > Interval * Speed)
			CarRoot.AddRelativeLocation(-FVector::ForwardVector * Speed * Interval);
	}
};