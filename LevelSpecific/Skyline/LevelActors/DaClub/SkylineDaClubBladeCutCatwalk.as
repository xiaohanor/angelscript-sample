class ASkylineDaClubBladeCutCatwalk : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsAxisRotateComponent RotateComp;
	default RotateComp.LocalRotationAxis = FVector::ForwardVector;
	default RotateComp.Friction = 3.0;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceComp;
	default ForceComp.Force = -FVector::UpVector * 3000.0;

	UPROPERTY(DefaultComponent)
	USkylineInterfaceComponent InterfaceComp;

	UPROPERTY(EditAnywhere)
	float ActivationDelay = 0.5;
	float ActivationTime = 0.0;

	TArray<AActor> ActivationActors;
	bool bShouldActivate = false;
	bool bIsActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForceComp.AddDisabler(this);

		InterfaceComp.OnActivated.AddUFunction(this, n"HandleActivated");
		ActivationActors = InterfaceComp.ListenToActors;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bIsActivated && bShouldActivate && Time::GameTimeSeconds > ActivationTime)
			Activate();
	}

	UFUNCTION()
	private void HandleActivated(AActor Caller)
	{
		ActivationActors.Remove(Caller);

		if (!bIsActivated && ActivationActors.Num() == 0)
		{
			bShouldActivate = true;
			ActivationTime = Time::GameTimeSeconds + ActivationDelay;
		}
	}

	UFUNCTION()
	void Activate()
	{
		bIsActivated = true;
		ForceComp.RemoveDisabler(this);
	}
};