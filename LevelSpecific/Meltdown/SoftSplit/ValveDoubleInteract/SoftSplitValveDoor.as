class ASoftSplitValveDoor : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent ReplicatedTranslateComp;

	UPROPERTY(EditInstanceOnly)
	ASoftSplitValveDoubleInteract Valve;

	UPROPERTY(EditAnywhere)
	float MaxForce = 1000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		Valve.OnCompleted.AddUFunction(this, n"HandleCompleted");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ForceComp.Force = FVector::UpVector * -MaxForce * Valve.TotalProgress;
		ReplicateMovement();
	}
	
	UFUNCTION()
	private void HandleCompleted()
	{
		TranslateComp.SpringStrength = 0.0;
	}

	private void ReplicateMovement()
	{
		ReplicatedTranslateComp.SetRelativeLocation(TranslateComp.RelativeLocation);
	}
};