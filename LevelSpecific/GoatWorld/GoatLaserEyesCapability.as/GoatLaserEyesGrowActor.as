class AGoatLaserEyesGrowActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent GrowRoot;

	UPROPERTY(DefaultComponent, Attach = GrowRoot)
	UGoatLaserEyesAutoAimComponent LaserEyesAutoAimComp;

	UPROPERTY(DefaultComponent)
	UGoatLaserEyesResponseComponent LaserEyesResponseComp;

	UPROPERTY()
	FGoatLaserEyesStartEvent OnLaserStarted;

	UPROPERTY()
	FGoatLaserEyesStopEvent OnLaserStopped;

	UPROPERTY(EditAnywhere)
	float MaxSize = 4.0;
	float CurrentSize = 1.0;
	float DefaultSize = 1.0;

	UPROPERTY(EditAnywhere)
	float GrowSpeed = 1.5;

	UPROPERTY(EditAnywhere)
	float ShrinkSpeed = 0.25;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LaserEyesResponseComp.OnLaserEyesStart.AddUFunction(this, n"StartLaser");
		LaserEyesResponseComp.OnLaserEyesStop.AddUFunction(this, n"StopLaser");

		CurrentSize = GetActorScale3D().X;
		DefaultSize = CurrentSize;
	}

	UFUNCTION()
	private void StartLaser()
	{
		OnLaserStarted.Broadcast();
	}

	UFUNCTION()
	private void StopLaser()
	{
		OnLaserStopped.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float TargetSize = LaserEyesResponseComp.bLasered ? MaxSize : DefaultSize;
		float Speed = LaserEyesResponseComp.bLasered ? GrowSpeed : ShrinkSpeed;
		CurrentSize = Math::FInterpTo(CurrentSize, TargetSize, DeltaTime, Speed);
		// SetActorScale3D(FVector(CurrentSize));
		GrowRoot.SetRelativeScale3D(FVector(CurrentSize));
	}
}