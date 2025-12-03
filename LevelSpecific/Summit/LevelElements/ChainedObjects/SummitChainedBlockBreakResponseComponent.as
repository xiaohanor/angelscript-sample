event void FOnSummitChainedBlockImpact();

class USummitChainedBlockBreakResponseComponent : UActorComponent
{
	UPROPERTY()
	FOnSummitChainedBlockImpact OnSummitChainedBlockImpact;
}