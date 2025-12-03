event void FonInteractionFinished();

class ASummitChainedBlockDoubleInteract : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;
	default RotateComp.ForceScalar = 0.75;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent BoxOverlapComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UFauxPhysicsWeightComponent WeightComp;

	UPROPERTY(EditAnywhere)
	ANightQueenChain Chain;

	TArray<AActor> AlreadyHit;

	int HitCount;

	UPROPERTY(EditAnywhere)
    ASummitNightQueenGem Gem;

	UPROPERTY()
	FonInteractionFinished InteractFinished;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WeightComp.AddDisabler(this);	
		Chain.OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
		Gem.OnSummitGemDestroyed.AddUFunction(this, n"OnCrystalSmashed");
		BoxOverlapComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
	}

	UFUNCTION()
	private void OnCrystalSmashed(ASummitNightQueenGem CrystalDestroyed)
	{
		HitCount++;
		HitCounter();
	}

	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{
			HitCount++;	
			HitCounter();
	}

	UFUNCTION()
	void HitCounter()
	{
		if(HitCount == 2)
			WeightComp.RemoveDisabler(this);	
			InteractFinished.Broadcast();

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