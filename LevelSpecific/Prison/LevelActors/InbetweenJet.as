UCLASS(Abstract)
class AInbetweenJet : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;


	UFUNCTION(BlueprintCallable)
	void StartCharge()
	{
		UInbetweenJetEventHandler::Trigger_JetStartCharge(this);
	}

	UFUNCTION(BlueprintCallable)
	void Launch()
	{
		UInbetweenJetEventHandler::Trigger_JetStartCharge(this);
	}

	UFUNCTION(BlueprintCallable)
	void Stop()
	{
		UInbetweenJetEventHandler::Trigger_JetStartCharge(this);
	}
};
