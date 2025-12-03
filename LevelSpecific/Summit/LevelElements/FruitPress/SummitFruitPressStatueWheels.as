class ASummitFruitPressStatueWheels : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 40000.0;

	float TargetSpeed = 100.0;
	float CurrentSpeed;

	bool bIsOn;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsOn)
		{
			CurrentSpeed = Math::FInterpConstantTo(CurrentSpeed, TargetSpeed, DeltaSeconds, TargetSpeed * 1.25);
		}
		else
		{
			CurrentSpeed = Math::FInterpConstantTo(CurrentSpeed, 0.0, DeltaSeconds, TargetSpeed * 1.5);
		}

		MeshRoot.AddLocalRotation(FRotator(CurrentSpeed, 0, 0) * DeltaSeconds);
	}

	void ChangeActivationMode(bool bNewIsOn)
	{
		bIsOn = bNewIsOn;
		if (bIsOn)
			USummitFruitPressStatueWheelsEffectHandler::Trigger_OnWheelStarted(this);
		else
			USummitFruitPressStatueWheelsEffectHandler::Trigger_OnWheelStopped(this);
	}
};