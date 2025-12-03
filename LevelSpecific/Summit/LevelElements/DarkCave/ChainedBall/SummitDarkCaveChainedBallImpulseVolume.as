class ASummitDarkCaveChainedBallImpulseVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BoxComp.SetCollisionResponseToChannel(ECollisionChannel::ECC_PhysicsBody, ECollisionResponse::ECR_Overlap);

	UPROPERTY(EditAnywhere)
	float Impulse = 5000.0;

	UPROPERTY(EditAnywhere)
	bool bAddImpulseOnce = true;
	bool bHaveAddedImpulse;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
	}
	
	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto Ball = Cast<ASummitDarkCaveChainedBall>(OtherActor);
		if (Ball == nullptr)
			return;
		
		if (bHaveAddedImpulse)
			return;

		Ball.AddMovementImpulse(ActorForwardVector * Impulse); 
		bHaveAddedImpulse = true;
	}
};