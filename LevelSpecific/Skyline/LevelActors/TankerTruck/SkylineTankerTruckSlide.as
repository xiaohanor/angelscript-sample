class ASkylineTankerTruckSlide : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent RotateForceComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent TranslateForceComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	USceneComponent MidSection;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RotateForceComp.AddDisabler(this);
		TranslateForceComp.AddDisabler(this);

		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		RotateComp.OnMaxConstraintHit.AddUFunction(this, n"HandleConstraintHit");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MidSection.RelativeLocation = FVector(Math::Min(490.0, TranslateComp.RelativeLocation.X), 0.0, 0.0);
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		RotateForceComp.RemoveDisabler(this);
	}

	UFUNCTION()
	private void HandleConstraintHit(float Strength)
	{
		TranslateForceComp.RemoveDisabler(this);
	}
};