class AStormSiegeCaveInSection : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EndLocation;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent OverlapComp;
	default OverlapComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default OverlapComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = EndLocation)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(15.0));
#endif

	float Speed = 5000.0;

	bool bActivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		OverlapComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshRoot.RelativeLocation = Math::VInterpConstantTo(MeshRoot.RelativeLocation, EndLocation.RelativeLocation, DeltaSeconds, Speed);

		float Dist = (MeshRoot.RelativeLocation - EndLocation.RelativeLocation).Size();
		
		if (Dist < 5.0)
			SetActorTickEnabled(false);
	}

	UFUNCTION()
	void ActivateCaveInCeiling()
	{
		SetActorTickEnabled(true);
		bActivated = true;
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (!bActivated)
			return;
		
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
		{
			Player.KillPlayer();
		}
	}
}