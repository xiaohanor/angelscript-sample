class ASummitMeltableFlagPole : ANightQueenMetal
{
	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AActor FlagActor;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float FlagActivateDelayFromStartedMelting = 0.1;
	
	bool bMeltedFunctionCalled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		OnNightQueenMetalStartedMelting.AddUFunction(this, n"OnStartedMelting");
	}

	UFUNCTION()
	private void OnStartedMelting()
	{
		Timer::SetTimer(this, n"OnMelted", FlagActivateDelayFromStartedMelting);
	}

	UFUNCTION(BlueprintEvent)
	private void OnMelted()
	{
		USummitMeltableFlagPoleEventHandler::Trigger_OnPoleMelted(this);
	}
};