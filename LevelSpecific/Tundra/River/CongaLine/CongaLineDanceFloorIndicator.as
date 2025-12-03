class ACongaLineDanceFloorIndicator : ACongaGlowingTile
{
	// UPROPERTY(EditAnywhere)
	// FLinearColor IndicatorColor;

	UPROPERTY(EditAnywhere)
	int ColorIndex;

	UPROPERTY(EditDefaultsOnly)
	float PulseDuration = 0.5;

	bool bIsActivated = false;
	float LastActivationTime;
	float ActiveDuration;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		SetDefaultColorByIndex(ColorIndex);

		CongaLine::GetManager().OnMonkeyBarFilledEvent.AddUFunction(this, n"ActivateIndicator");
		CongaLine::GetManager().OnMonkeyBarLostEvent.AddUFunction(this, n"DeactivateIndicator");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		if(!bIsActivated)
			return;

		ActiveDuration += DeltaSeconds;
		if(Time::GameTimeSeconds - LastActivationTime >= PulseDuration)
		{
			LastActivationTime = Time::GameTimeSeconds;
			SetActive(!bIsActive);
		}
	}

	UFUNCTION()
	private void ActivateIndicator()
	{
		bIsActivated = true;
		LastActivationTime = Time::GameTimeSeconds;
		ActiveDuration = 0;
		SetActive(true);
	}

	UFUNCTION()
	private void DeactivateIndicator()
	{
		SetActive(false);
		bIsActivated = false;
	}
};