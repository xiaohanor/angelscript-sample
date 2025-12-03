class ASummitDarkCaveChainedBallRespawnVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent ResetLocationComp;
	default ResetLocationComp.SetWorldScale3D(FVector(5.0)); 

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);
	default BoxComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);
	default BoxComp.LineThickness = 10.0;
	default BoxComp.ShapeColor = FColor::Green;
	default BoxComp.SetWorldScale3D(FVector(10));
	default BoxComp.SetMobility(EComponentMobility::Movable);

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
		Ball.SetNewRelocation(ResetLocationComp.WorldLocation);
	}
};