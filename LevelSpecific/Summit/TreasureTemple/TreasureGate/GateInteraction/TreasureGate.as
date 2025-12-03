class ATreasureGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DoorRoot1;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DoorRoot2;

	UPROPERTY()
	float RotateAmount = 90.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION()
	void ActivateGate()
	{
		BP_OpenGate();
		UTreasureGateEventHandler::Trigger_OnGateStartOpening(this);
	}

	UFUNCTION()
	void DeactivateGate()
	{
		BP_CloseGate();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OpenGate() {}

	UFUNCTION(BlueprintEvent)
	void BP_CloseGate() {}

	UFUNCTION(BlueprintCallable)
	void OnGateFinishedOpening()
	{
		UTreasureGateEventHandler::Trigger_OnGateFinishedOpening(this);
	}
}