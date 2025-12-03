class ASanctuaryLakePillar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsSpringConstraint Spring;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComponent;

	UPROPERTY(DefaultComponent)
	UDarkPortalFauxPhysicsReactionComponent DarkPortalFauxPhysicsReactionComponent;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UStaticMeshComponent PillarMesh;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UStaticMeshComponent GrabMesh;
	
	UPROPERTY(DefaultComponent, Attach = GrabMesh)
	UDarkPortalTargetComponent TargetComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	USceneComponent VFXLocation1;
	UPROPERTY(DefaultComponent, Attach = RotateComp)
	USceneComponent VFXLocation2;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem VFX;

	bool bSpringDisabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForceComp.AddDisabler(this);
		RotateComp.OnMinConstraintHit.AddUFunction(this, n"HandleMinConstraintHit");
		DarkPortalResponseComponent.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
//		PrintToScreen("" + RotateComp.CurrentRotation, 0.0);
		if (!bSpringDisabled && RotateComp.CurrentRotation < -0.04)
		{
			Spring.AddDisabler(this);
			ForceComp.RemoveDisabler(this);
			bSpringDisabled = true;
		}
	}

	UFUNCTION()
	private void HandleGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{	
		//RotateComp.ForceScalar = 1.0;
		//ForceComp.Force = FVector(0.0,0.0,-500.0);
	}

	UFUNCTION()
	private void HandleMinConstraintHit(float Strength)
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(VFX, VFXLocation1.GetWorldLocation());
		Niagara::SpawnOneShotNiagaraSystemAtLocation(VFX, VFXLocation2.GetWorldLocation());
	}
};