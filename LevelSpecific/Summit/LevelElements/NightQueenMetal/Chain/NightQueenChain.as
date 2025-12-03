event void ENightQueenChainOnMeltedEvent(ANightQueenChain Chain);

class ANightQueenChain : ANightQueenMetal
{ 
	ENightQueenChainOnMeltedEvent OnChainMelted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		OnNightQueenMetalMelted.AddUFunction(this, n"OnMelted");
		OnNightQueenMetalRecovered.AddUFunction(this, n"OnRecovered");		
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnMelted()
	{
		AutoAimComp.Disable(this);
		OnChainMelted.Broadcast(this);
		UNightQueenMetalChainEventHandler::Trigger_OnMelted(this);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnRecovered()
	{
		AutoAimComp.Enable(this);
		UNightQueenMetalChainEventHandler::Trigger_OnRecovered(this);
	}
}