class ASummitTopDownMazeRevolvingDoorWheel : AHazeActor
{
	UPROPERTY(DefaultComponent,RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(EditAnywhere, Category = "Setup")
	ASummitRollingWheel Wheel;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float RotationSpeed = 0.05;

	UPROPERTY(EditAnywhere)
	bool bCounterSpin;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Wheel.OnWheelRolled.AddUFunction(this, n"RotateDoor");
	}

	UFUNCTION()
	private void RotateDoor(float Amount)
	{
		FRotator AdditionalRotation = FRotator(0, Amount * RotationSpeed, 0);
		if(bCounterSpin == true )
			MeshRoot.RelativeRotation += AdditionalRotation;
		else
			MeshRoot.RelativeRotation -= AdditionalRotation;
	}
};