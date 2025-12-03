class AGoatLaserEyesSpinnyObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SpinnyRoot;

	UPROPERTY(DefaultComponent, Attach = SpinnyRoot)
	UGoatLaserEyesAutoAimComponent LaserEyesAutoAimComp;

	UPROPERTY(DefaultComponent)
	UGoatLaserEyesResponseComponent LaserEyesResponseComp;

	UPROPERTY(EditAnywhere)
	float SpinRate = 60.0;
	float DefaultSpinRate;

	UPROPERTY(EditAnywhere)
	float SpinMaxMultiplier = 8.0;
	float CurrentSpinMultiplier = 1.0;

	UPROPERTY(EditAnywhere)
	float SpinIncreaseSpeed = 3.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DefaultSpinRate = SpinRate;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float TargetSpinRate = LaserEyesResponseComp.bLasered ? DefaultSpinRate * SpinMaxMultiplier : DefaultSpinRate;
		SpinRate = Math::FInterpTo(SpinRate, TargetSpinRate, DeltaTime, SpinIncreaseSpeed);
		SpinnyRoot.AddLocalRotation(FRotator(0.0, SpinRate * DeltaTime, 0.0));
	}
}