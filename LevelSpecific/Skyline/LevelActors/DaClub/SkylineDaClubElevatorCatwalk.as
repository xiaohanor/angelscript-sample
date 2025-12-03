class ASkylineDaClubElevatorCatwalk : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent WireAffectedPivot;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditAnywhere)
	ASkylineDaClubCatwalkWire CatwalkWire;

	UPROPERTY(EditAnywhere)
	float Height = 500.0;

	private float MovementAlpha = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddTickPrerequisiteActor(CatwalkWire);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MovementAlpha = CatwalkWire.TranslateComp.RelativeLocation.Z / CatwalkWire.TranslateComp.MinZ;
		WireAffectedPivot.SetRelativeLocation(FVector::UpVector * MovementAlpha * Height);
	}

	UFUNCTION(BlueprintPure)
	float GetMovementAlpha()
	{
		return MovementAlpha;
	}
};