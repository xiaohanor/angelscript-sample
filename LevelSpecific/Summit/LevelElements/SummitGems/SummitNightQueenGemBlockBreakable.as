class ASummitNightQueenGemBlockBreakable : ASummitNightQueenGem
{
	UPROPERTY(DefaultComponent)
	USummitChainedBlockBreakResponseComponent ChainBlockResponseComp;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		ChainBlockResponseComp.OnSummitChainedBlockImpact.AddUFunction(this, n"OnSummitChainedBlockImpact");	
	}

	UFUNCTION()
	private void OnSummitChainedBlockImpact()
	{
		DestroyCrystal();
	}
}