struct FSummitLinkedChainOnLinkMeltedParams
{
	UPROPERTY()
	FVector LocationOfLink;

	UPROPERTY()
	int NumberOfLinksFalling;
}

UCLASS(Abstract)
class USummitLinkedChainEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLinkMelted(FSummitLinkedChainOnLinkMeltedParams Params) {} 
};