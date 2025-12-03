class AChainedSculptureDropWeight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = BoxComp)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent OverlapBreakComp;
	default OverlapBreakComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabiltityComp;
	// default CapabiltityComp.DefaultCapabilities.Add(n"ChainedSculptureReturnCapability");

	UPROPERTY(EditAnywhere)
	ANightQueenChain Metal;

	UPROPERTY(EditAnywhere)
	TArray<AActor> AttachActors;

	bool bReturning;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (Metal != nullptr)
			AttachToComponent(Metal.RootComponent, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);

		for (AActor Actor : AttachActors)
		{
			Actor.AttachToComponent(BoxComp, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		}

		Metal.OnNightQueenMetalMelted.AddUFunction(this, n"OnSummitOnMelted");
		OverlapBreakComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
	}

	UFUNCTION()
	private void OnSummitOnMelted()
	{
		BoxComp.SetSimulatePhysics(true);
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		USummitDestructibleResponseComponent ResponseComp = USummitDestructibleResponseComponent::Get(OtherActor);

		if (ResponseComp != nullptr)
		{
			ResponseComp.OnSummitDestructibleDestroyed.Broadcast();
		}
		
		// if (OtherActor != this)
		// 	DestroyActor();
	}
}