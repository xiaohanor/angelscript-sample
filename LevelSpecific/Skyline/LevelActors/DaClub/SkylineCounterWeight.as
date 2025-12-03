class ASkylineCounterWeight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.Friction = 0.1;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.bConstrainZ = true;
	default TranslateComp.MinZ = -1000.0;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;
	default ForceComp.Force = -FVector::UpVector * 3000.0;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForceComp.AddDisabler(this);
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		ForceComp.RemoveDisabler(this);
	}
};