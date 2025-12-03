class ASummitPulleyCrane : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = "MeshRoot")
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = "MeshRoot")
	UStaticMeshComponent Crane;

	UPROPERTY(EditAnywhere)
	ASummitRollingWheel RollingWheel;

	bool bIsPulling;

	FRotator StartRot;
	FRotator CurrentRot;

	float PullTarget;
	FHazeAcceleratedFloat AccelFloat;

	float PullMax = 5000.0;

	UPROPERTY(EditAnywhere)
	float SpeedMultiplier = 1.0;

	UPROPERTY(EditAnywhere)
	float PullAcceleration = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartRot = FRotator(0,0,0);
		RollingWheel.OnWheelRolled.AddUFunction(this, n"OnWheelRolled");
		AccelFloat.SnapTo(0.0);
	}

	UFUNCTION()
	private void OnWheelRolled(float Amount)
	{
		PullTarget += Amount * SpeedMultiplier;
		PullTarget = Math::Clamp(PullTarget, 0.0, PullMax);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentRot = MeshRoot.RelativeRotation;
		float Alpha = PullTarget / PullMax;
		AccelFloat.AccelerateTo(Alpha, PullAcceleration, DeltaSeconds);
		MeshRoot.RelativeRotation = FQuat::Slerp(StartRot.Quaternion(), FRotator(-45, 0, 0).Quaternion(), 1.0 - AccelFloat.Value).Rotator();
	}
}