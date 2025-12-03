class ASkylinePhoneGamePhoneCall : ASkylinePhoneGame
{
	UPROPERTY(DefaultComponent)
	USkylinePhoneGameButtonComponent AnswerButton;

	UPROPERTY(DefaultComponent)
	USkylinePhoneGameButtonComponent DeclineButton;

	UPROPERTY(DefaultComponent)
	UTextRenderComponent CallTimeTextRenderComp;

	UPROPERTY()
	float CallTime = 0.0;
	bool bInCall = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AnswerButton.OnButtonPressed.AddUFunction(this, n"AnswerButtonPressed");
		DeclineButton.OnButtonPressed.AddUFunction(this, n"DeclineButtonPressed");
	}

	UFUNCTION()
	private void AnswerButtonPressed()
	{
		CallTimeTextRenderComp.SetHiddenInGame(false);
		bInCall = true;
		AnswerButton.SetRelativeLocation(FVector(0.0, 300.0, 0.0));
		DeclineButton.SetRelativeLocation(FVector(0.0, 0.0, -90.0));
	}

	UFUNCTION()
	private void DeclineButtonPressed()
	{
		RestartPhoneGame();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		
		if (bInCall)
			CallTime += DeltaSeconds;
	}
};