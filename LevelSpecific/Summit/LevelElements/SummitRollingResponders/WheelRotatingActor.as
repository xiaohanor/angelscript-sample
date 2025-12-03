class AWheelRotatingActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	default RootComp.SetWorldScale3D(FVector(15.0));

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UArrowComponent Forward;

	UPROPERTY(EditAnywhere)
	ASummitRollingWheelOnRail RollingWheel;

	UPROPERTY(EditAnywhere)
	bool bInvertDirection;

	UPROPERTY(EditAnywhere)
	TArray<AActor> AttachActors;

	UPROPERTY(EditAnywhere)
	FRotator RotationValues = FRotator(0.0, 1.0, 0.0);

	UPROPERTY(EditAnywhere)
	float RotationSpeed = 40.0;

	UPROPERTY(EditAnywhere)
	float RotationMultiplier = 0.05;

	FHazeAcceleratedFloat AccelYawAmount;
	float YawTarget;

	bool bWheelRotating;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RollingWheel.OnWheelRolled.AddUFunction(this, n"OnWheelRolled");
		AccelYawAmount.SnapTo(0.0);

		for (AActor Actor : AttachActors)
		{
			Actor.AttachToComponent(RootComp, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		}
	}

	UFUNCTION()
	private void OnWheelRolled(float Amount)
	{
		FRotator AdditionalRotation;
		if(bInvertDirection)
			AdditionalRotation = RotationValues * -Amount * RotationMultiplier;
		else
			AdditionalRotation = RotationValues * Amount * RotationMultiplier;

		RootComp.AddRelativeRotation(AdditionalRotation);
		// if (Amount > 0.0)
		// {
		// 	if (bInvertDirection)
		// 		YawTarget = -RotationSpeed;
		// 	else
		// 		YawTarget = RotationSpeed;

		// }
		// else if (Amount < 0.0)
		// {
		// 	if (bInvertDirection)
		// 		YawTarget = RotationSpeed;
		// 	else
		// 		YawTarget = -RotationSpeed;

		// }
		// PrintToScreen("WE ARE ROTATING");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// PrintToScreen("YawTarget: " + YawTarget);
		// AccelYawAmount.AccelerateTo(YawTarget * 0.5, 3.0, DeltaTime);
		// MeshRoot.AddRelativeRotation(RotationValues * AccelYawAmount.Value * DeltaTime);
		// AddActorWorldRotation(RotationValues * AccelYawAmount.Value * DeltaTime);
		// PrintToScreen("Rot Per Second: " + RotationValues * AccelYawAmount.Value);
		// YawTarget = 0.0;
	}
}