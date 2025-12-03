class AMeltableCounterWeightMovingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.bConstrainZ = true;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = ForceComp)
	UStaticMeshComponent PlatformMeshComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 60000.0;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AMeltableCounterWeight CounterWeight;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MoveMax = 4000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MoveForce = 15000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FVector MoveDirection = FVector(0, 0, 1.0);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(CounterWeight != nullptr)
			CounterWeight.OnWeightStartsFalling.AddUFunction(this, n"OnWeightStartsFalling");

		ForceComp.AddDisabler(this);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		FVector MaxLocation = MoveDirection * MoveMax;

		TranslateComp.MaxZ = MaxLocation.Z;
		TranslateComp.MaxY = MaxLocation.Y;
		TranslateComp.MaxX = MaxLocation.X;
		ForceComp.Force = ActorTransform.TransformVector(MoveDirection * (MoveForce * Math::Sign(MoveMax)));
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnWeightStartsFalling(AMeltableCounterWeight CurrentCounterWeight)
	{
		ForceComp.RemoveDisabler(this);
	}
};