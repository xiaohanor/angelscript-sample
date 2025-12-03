class ASummitChainedBlock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;
	default RotateComp.ForceScalar = 0.75;
	default RotateComp.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::SyncedFromActorControl;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent BoxOverlapComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UFauxPhysicsWeightComponent WeightComp;

	UPROPERTY(EditAnywhere)
	ANightQueenChain Chain;

	TArray<AActor> AlreadyHit;

	int MaxHit;
	int CurrentHit;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent GongAttachLocation;

	UPROPERTY(EditAnywhere)
    ASummitSoundCrystalGong GongActor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(GongActor != nullptr)
			GongActor.AttachToComponent(GongAttachLocation);

		WeightComp.AddDisabler(this);	
		Chain.OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
		BoxOverlapComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
	}

	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{
		WeightComp.RemoveDisabler(this);	
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (AlreadyHit.Contains(OtherActor))
			return;

		AlreadyHit.Add(OtherActor);

		USummitChainedBlockBreakResponseComponent ResponseComp = USummitChainedBlockBreakResponseComponent::Get(OtherActor);
		UGoldGiantBreakResponseComponent BreakComp = UGoldGiantBreakResponseComponent::Get(OtherActor);

		if (ResponseComp != nullptr)
		{
			ResponseComp.OnSummitChainedBlockImpact.Broadcast();
		}

		if (BreakComp != nullptr)
		{
			FVector Direction = (OtherActor.ActorLocation - ActorLocation).GetSafeNormal();
			BreakComp.OnBreakGiantObject.Broadcast(Direction, 80000.0);
		}
	}
}