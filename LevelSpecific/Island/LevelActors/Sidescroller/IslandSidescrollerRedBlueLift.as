class AIslandSidescrollerRedBlueLift : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.bConstrainZ = true;
	default TranslateComp.MinZ = -710.0;
	default TranslateComp.MaxZ = 450.0;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent LiftMesh;

	UPROPERTY(EditAnywhere, Category = "Setup")
	AIslandShootableActivator GoUpActivator;

	UPROPERTY(EditAnywhere, Category = "Setup")
	AIslandShootableActivator GoDownActivator;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ForcePerShot = 40.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GoUpActivator.OnImpact.AddUFunction(this, n"OnGoUpActivatorImpacted");
		GoDownActivator.OnImpact.AddUFunction(this, n"OnGoDownActivatorImpacted");

		GoUpActivator.AttachToComponent(LiftMesh, n"NAME_None", EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, true);
		GoDownActivator.AttachToComponent(LiftMesh, n"NAME_None", EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, true);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnGoUpActivatorImpacted()
	{
		FVector Impulse = TranslateComp.UpVector * ForcePerShot;
		FauxPhysics::ApplyFauxImpulseToActor(this, Impulse);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnGoDownActivatorImpacted()
	{
		FVector Impulse = -TranslateComp.UpVector * ForcePerShot;
		FauxPhysics::ApplyFauxImpulseToActor(this, Impulse);
	}
};