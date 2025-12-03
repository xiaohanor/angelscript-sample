class ASummitDarkCaveWindRotator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	float MaxSpeed = 700.0;
	float TargetSpeed;
	float CurrentSped;

	UPROPERTY(EditInstanceOnly)
	ASummitAirCurrent AirCurrent;

	UPROPERTY(EditInstanceOnly)
	bool bStartDisabled = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bStartDisabled)
			AirCurrent.Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentSped = Math::FInterpConstantTo(CurrentSped, TargetSpeed, DeltaSeconds, MaxSpeed);
		AddActorLocalRotation(FRotator(0, CurrentSped * DeltaSeconds, 0));
	}

	UFUNCTION()
	void TurnOn()
	{
		TargetSpeed = MaxSpeed;
		AirCurrent.RemoveStartDisabler();
	}

	UFUNCTION()
	void TurnOff()
	{
		TargetSpeed = 0;
		AirCurrent.Deactivate();
	}
};