event void FSplitTraversalRevealStairs();

UCLASS(Abstract)
class USplitTraversalRevealingStaircaseEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnActivated() {}
}

class ASplitTraversalRevealingStaircase : AWorldLinkDoubleActor
{
	UPROPERTY()
	FSplitTraversalRevealStairs OnStairsRevealed;

	UPROPERTY(DefaultComponent)
	USplitTraversalButtonResponseComponent ResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		ResponseComp.OnPulseArrived.AddUFunction(this, n"HandleActivated");
	}

	UFUNCTION()
	private void HandleActivated()
	{
		OnStairsRevealed.Broadcast();

		USplitTraversalRevealingStaircaseEventHandler::Trigger_OnActivated(this);
	}
}
