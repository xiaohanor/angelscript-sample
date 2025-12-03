class ASummitMultiChainedGemBlock : AHazeActor
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

	// UPROPERTY(EditAnywhere)
	// TArray<ANightQueenChain> Chains;
	
	UPROPERTY(EditAnywhere)
	ASummitNightQueenGem Gem;

	TArray<AActor> AlreadyHit;

	int MaxHits;
	int CurrentHits;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Gem.OnSummitGemDestroyed.AddUFunction(this, n"OnSummitGemDestroyed");

		// MaxHits = Chains.Num() - 1;
		// for (ANightQueenChain Chain : Chains)
		// {
		// 	Chain.OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
		// }

		WeightComp.AddDisabler(this);	

		BoxOverlapComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
	}

	UFUNCTION()
	private void OnSummitGemDestroyed(ASummitNightQueenGem CrystalDestroyed)
	{
		WeightComp.RemoveDisabler(this);	
	}

	// UFUNCTION()
	// private void OnNightQueenMetalMelted()
	// {
	// 	CurrentHits++;

	// 	if (CurrentHits >= MaxHits)
	// 	{
	// 		WeightComp.RemoveDisabler(this);	

	// 	}
	// }

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