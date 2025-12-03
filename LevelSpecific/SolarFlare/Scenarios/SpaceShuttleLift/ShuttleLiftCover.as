class AShuttleLiftCover : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent PhysicsAxisComp;

	UPROPERTY(DefaultComponent, Attach = PhysicsAxisComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent)
	USolarFlarePlayerCoverComponent CoverComp;
	default CoverComp.Distance = 1000.0;

	UPROPERTY(EditAnywhere)
	ASolarFlareWaveImpactEventActor EventActor;

	float CurrentForce;
	float MaxForce = 1000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		EventActor.OnSolarWaveImpactEventActorTriggered.AddUFunction(this, n"OnSolarWaveImpactEventActorTriggered");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentForce = Math::FInterpConstantTo(CurrentForce, 0.0, DeltaSeconds, MaxForce);
		ForceComp.Force = FVector(CurrentForce, 0, 0);
	}

	UFUNCTION()
	private void OnSolarWaveImpactEventActorTriggered()
	{
		CurrentForce = MaxForce;
	}
};