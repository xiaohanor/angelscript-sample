class ASkylineInnerCityBillboard : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsAxisRotateComponent RotateComp;
	default RotateComp.LocalRotationAxis = FVector::ForwardVector;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent FauxPhysicsForceComp;
	default FauxPhysicsForceComp.bWorldSpace = false;
	default FauxPhysicsForceComp.Force = FVector::UpVector * 5000.0;
	default FauxPhysicsForceComp.RelativeLocation = FVector::RightVector * 200.0;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UStaticMeshComponent BillboardMesh;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike Timelike;

	float LockCounter;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LockCounter = 0.0;
		FauxPhysicsForceComp.AddDisabler(this);
		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		Timelike.BindUpdate(this, n"HandleAnimationUpdate");
	}

	UFUNCTION()
	private void HandleAnimationUpdate(float CurrentValue)
	{
		BillboardMesh.RelativeRotation = FRotator(CurrentValue * -1.0, 0.0, 0.0);
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{	
		LockCounter++;
		
		if(LockCounter>=2.0)
		{
		Timelike.Play();
		}
		
		
	}

	UFUNCTION()
	void Unlocked()
	{
		if(LockCounter>=2.0)
		{
		FauxPhysicsForceComp.RemoveDisabler(this);
		}
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
		PrintToScreen("LockCounter" + LockCounter);
	}
};