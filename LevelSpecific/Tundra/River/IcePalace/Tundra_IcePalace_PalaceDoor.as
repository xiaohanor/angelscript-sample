class ATundra_IcePalace_PalaceDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(EditInstanceOnly)
	float MaxYawRotation = 20;

	UPROPERTY(EditInstanceOnly)
	float MinYawRotation = 0;

	UPROPERTY(EditInstanceOnly)
	bool bInvertInput = false;
	
	float RotationSpeed = 10;

	UPROPERTY(EditInstanceOnly)
	ATundraRangedLifeGivingActor LifeGivingActor;

	bool bInteracting = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LifeGivingActor.OnInteractStart.AddUFunction(this, n"OnInteractionStarted");
		LifeGivingActor.OnInteractStop.AddUFunction(this, n"OnInteractionStopped");

		if(bInvertInput)
			RotationSpeed *= -1;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bInteracting)
			return;

		float Input = LifeGivingActor.LifeReceivingComponent.RawVerticalInput;

		float TargetYaw = MeshRoot.RelativeRotation.Yaw + Input * DeltaSeconds * RotationSpeed;
		TargetYaw = Math::Clamp(TargetYaw, MinYawRotation, MaxYawRotation);
		
		MeshRoot.SetRelativeRotation(FRotator(0, TargetYaw, 0));
	}

	UFUNCTION()
	private void OnInteractionStarted(bool bForced)
	{
		bInteracting = true;
	}

	UFUNCTION()
	private void OnInteractionStopped(bool bForced)
	{
		bInteracting = false;
	}
};