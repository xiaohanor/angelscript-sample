class AMeltdownBossPhaseTwoBigHammer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent SceneRoot;

	UPROPERTY(DefaultComponent)
	UBillboardComponent HammerTarget;

	UPROPERTY(DefaultComponent)
	UScenepointComponent HammerRoot;

	FHazeTimeLike HammerMove;
	default HammerMove.Duration = 1.0;
	default HammerMove.UseSmoothCurveZeroToOne();

	UPROPERTY()
	FVector CurrentLocation;
	UPROPERTY()
	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentLocation = ActorLocation;
		
		HammerMove.BindUpdate(this, n"HammerUpdate");
		HammerMove.BindFinished(this, n"HammerFinished");
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintCallable)
	void StartHammer()
	{
		RemoveActorDisable(this);
		HammerMove.PlayFromStart();
	}

	UFUNCTION(BlueprintCallable)
	void StopHammer()
	{
		AddActorDisable(this);
	}


	UFUNCTION()
	private void HammerUpdate(float CurrentValue)
	{
		SetActorLocation(Math::Lerp(CurrentLocation,TargetLocation, CurrentValue));
	}

	UFUNCTION(BlueprintEvent)
	private void HammerFinished()
	{
	
	}

};