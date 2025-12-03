class ASkylineCarTowerEventCars : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent CarPivot;

	UPROPERTY(DefaultComponent, Attach = CarPivot)
	USceneComponent SpinCarPivot;

	UPROPERTY(DefaultComponent, Attach = SpinCarPivot)
	UStaticMeshComponent WholeCar;

	UPROPERTY(DefaultComponent, Attach = SpinCarPivot)
	UStaticMeshComponent BrokenCar;

	UPROPERTY(DefaultComponent)
	USkylineBallBossLaserResponseComponent LaserComp;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike TimeLike;

	UPROPERTY(EditAnywhere)
	float RotationSpeed = Math::RandRange(400, 950);

	

	bool bDoOnce = true;
	bool bDisableOnce = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LaserComp.OnLaserOverlap.AddUFunction(this, n"HandleOnLaser");
	
		SetActorTickEnabled(false);
		BrokenCar.SetHiddenInGame(true);
		TimeLike.BindUpdate(this, n"UpdateAnimation");
		TimeLike.BindFinished(this, n"FinishedTimelike");
	}



	UFUNCTION()
	private void FinishedTimelike()
	{
		if(TimeLike.IsReversed() && bDisableOnce)
		{
			bDisableOnce = false;
			CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
			Explode();
 			AddActorDisable(this);
		}else

		TimeLike.Reverse();
	}

	UFUNCTION()
	private void UpdateAnimation(float CurrentValue)
	{
		CarPivot.SetRelativeLocation(FVector(0.0, 0.0, 450 * CurrentValue));
	}

	UFUNCTION()
	private void HandleOnLaser(bool bOverlap)
	{
		if(!bDoOnce)
			return;


		SetActorTickEnabled(true);
		TimeLike.Play();
		BrokenCar.SetHiddenInGame(false);
		WholeCar.SetHiddenInGame(true);
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		Explode();
		bDoOnce = false;
	}





	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SpinCarPivot.AddLocalRotation(FRotator(0.0, 0.0, RotationSpeed * DeltaSeconds));

		//PrintToScreen("RotationSpeed: " + RotationSpeed);
	}

	UFUNCTION(BlueprintEvent)
	void Explode()
	{
		
	}
	
};