class ASkylineDaClubFallingCatwalk : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent WireAffectedPivot;

	UPROPERTY(DefaultComponent, Attach = WireAffectedPivot)
	UFauxPhysicsAxisRotateComponent RotateComp;
	default RotateComp.LocalRotationAxis = FVector::RightVector;
	default RotateComp.Friction = 1.0;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceComp;
	default ForceComp.Force = -FVector::UpVector * 1000.0;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditAnywhere)
	ASkylineDaClubCatwalkWire CatwalkWire;

	UPROPERTY(EditAnywhere)
	float Angle = 30.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForceComp.AddDisabler(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Alpha = CatwalkWire.TranslateComp.RelativeLocation.Z / CatwalkWire.TranslateComp.MinZ;
		PrintToScreen("WireAlpha: " + Alpha, 0.0, FLinearColor::Green);
	
		WireAffectedPivot.SetRelativeRotation(FRotator(Alpha * Angle, 0.0, 0.0));
	}
};