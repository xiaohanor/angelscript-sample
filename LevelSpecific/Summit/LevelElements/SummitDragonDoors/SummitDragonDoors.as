class ASummitDragonDoors : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DoorRoot;
	default DoorRoot.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = DoorRoot)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bRespondToRollingWheel;

	UPROPERTY(EditAnywhere, Category = "Setup", Meta = (EditCondition = "bRespondToRollingWheel", EditConditionHides))
	ASummitRollingWheel RollingWheel;

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bRespondToTurningWheel;

	UPROPERTY(EditAnywhere, Category = "Setup", Meta = (EditCondition = "bRespondToTurningWheel", EditConditionHides))
	ASummitTurningWheel TurningWheel;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent OpenLocation;
	default OpenLocation.SetWorldScale3D(FVector(2.0));	

	UPROPERTY(EditAnywhere, Category = "Settings")
	float SpinForceScale = 1.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float OpenForce = 300.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ReturnForce = 500.0;

	FHazeAcceleratedFloat AccelForce;
	FVector ClosedLocation;

	float TotalDistance;
	float WheelForce;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ClosedLocation = DoorRoot.RelativeLocation;
		TotalDistance = (OpenLocation.RelativeLocation - ClosedLocation).Size();
		AccelForce.SnapTo(0.0);

		if (RollingWheel != nullptr)
			RollingWheel.OnWheelRolled.AddUFunction(this, n"OnWheelRolled");
		if (TurningWheel != nullptr)
			TurningWheel.OnWheelTurning.AddUFunction(this, n"OnWheelTurning");
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (WheelForce > 0.0)
			AccelForce.AccelerateTo(OpenForce, 0.5, DeltaTime);
		else if (WheelForce < 0.0)
			AccelForce.AccelerateTo(-OpenForce, 1.5, DeltaTime);
		else
			AccelForce.AccelerateTo(-ReturnForce, 1.5, DeltaTime);

		if (AccelForce.Value > 0.0)
			DoorRoot.RelativeLocation = Math::VInterpConstantTo(DoorRoot.RelativeLocation, OpenLocation.RelativeLocation, DeltaTime, AccelForce.Value);
		else
			DoorRoot.RelativeLocation = Math::VInterpConstantTo(DoorRoot.RelativeLocation, ClosedLocation, DeltaTime, Math::Abs(AccelForce.Value));

		WheelForce = 0.0;
	}

	bool IsDoorClosed()
	{
		return DoorRoot.RelativeLocation == ClosedLocation;
	}

	float GetOpenedPercentage()
	{
		return (DoorRoot.RelativeLocation - ClosedLocation).Size() / TotalDistance;
	}
	
	UFUNCTION()
	private void OnWheelRolled(float Amount)
	{
		WheelForce = Amount;
	}
	
	UFUNCTION()
	private void OnWheelTurning(float TurnAmount)
	{
		WheelForce = -TurnAmount * 8.0;
		PrintToScreen("WheelForce: " + WheelForce);
	}
}