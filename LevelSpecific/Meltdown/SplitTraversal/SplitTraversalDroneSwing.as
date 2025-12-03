class ASplitTraversalDroneSwing : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent DroneRoot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector DroneRelativeLocation = FVector::UpVector * Math::Sin(Time::GameTimeSeconds * 0.75) * 30.0;
		FRotator DroneRelativeRotation = FRotator(0.0, Math::Sin(Time::GameTimeSeconds * 0.5) * 20.0, 0.0);
		DroneRoot.SetRelativeLocationAndRotation(DroneRelativeLocation, DroneRelativeRotation);
	}
};