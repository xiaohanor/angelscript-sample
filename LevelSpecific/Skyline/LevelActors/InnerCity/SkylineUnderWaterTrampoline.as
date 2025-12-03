class ASkylineUnderWaterTrampoline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent FauxPhysicsTranslateComponent;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComponent)
	UStaticMeshComponent TrampolineMesh;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComponent)
	UGravityWhipTargetComponent GravityWhipTargetComponent;

	UPROPERTY(DefaultComponent, Attach = GravityWhipTargetComponent)
	UTargetableOutlineComponent GravityWhipOutlineComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipFauxPhysicsComponent GravityWhipFauxPhysicsComponent;

	UPROPERTY(DefaultComponent)
	UGravityWhipResponseComponent GravityWhipResponseComponent;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComponent)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForceComp.AddDisabler(this);
		GravityWhipTargetComponent.Disable(this);
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		ForceComp.RemoveDisabler(this);
		GravityWhipTargetComponent.Enable(this);
	}
};