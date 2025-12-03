event void FLightBirdChargeSignature();

class ULightBirdChargeComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	// Charge time required until fully charged.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response")
	float ChargeDuration = 1.0;

	// Modifies the charge power, where 1.0 is equal to delta time.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response")
	float ChargeMultiplier = 1.0;

	// Modifies the charge decay, where 1.0 is equal to delta time.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response")
	float DecayMultiplier = 1.0;
	
	// Delay before charge starts depleting.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response")
	float DecayDelay = 0.6;

	// Current charge time.
	UPROPERTY(NotEditable, BlueprintReadOnly, Category = "Response")
	float ChargeTime = 0.0;

	UPROPERTY(Category = "Response")
	FLightBirdChargeSignature OnFullyCharged;
	UPROPERTY(Category = "Response")
	FLightBirdChargeSignature OnChargeDepleted;

	private ULightBirdResponseComponent ResponseComponent;
	private float DecayTimestamp;
	private bool bEventTriggered;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComponent = ULightBirdResponseComponent::GetOrCreate(Owner);
		ResponseComponent.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
		ResponseComponent.OnUnilluminated.AddUFunction(this, n"HandleUnilluminated");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		ResponseComponent.OnIlluminated.Unbind(this, n"HandleIlluminated");
		ResponseComponent.OnUnilluminated.Unbind(this, n"HandleUnilluminated");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (ResponseComponent.IsIlluminated())
		{
			ChargeTime = Math::Min(ChargeTime + DeltaTime * ChargeMultiplier, ChargeDuration);
		}
		else
		{
			if (Time::GetGameTimeSince(DecayTimestamp) >= DecayDelay)
				ChargeTime = Math::Max(ChargeTime - DeltaTime * DecayMultiplier, 0.0);

			if (Math::IsNearlyZero(ChargeTime))
			{
				ChargeTime = 0.0;
				bEventTriggered = false;
				SetComponentTickEnabled(false);
				ChargeDepleted();
			}
		}

		if (!bEventTriggered && ChargeTime >= ChargeDuration)
		{
			bEventTriggered = true;
			FullyCharged();
		}
	}

	UFUNCTION()
	private void HandleIlluminated()
	{
		if (ResponseComponent.IsIlluminated())
			SetComponentTickEnabled(true);
	}

	UFUNCTION()
	private void HandleUnilluminated()
	{
		DecayTimestamp = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintPure)
	float GetChargeFraction() const property
	{
		return Math::Clamp(ChargeTime / ChargeDuration, 0.0, 1.0);
	}

	void FullyCharged()
	{
		if (HasControl())
			CrumbFullyCharged();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbFullyCharged()
	{
		OnFullyCharged.Broadcast();
	}

	void ChargeDepleted()
	{
		if (HasControl())
			CrumbChargeDepleted();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbChargeDepleted()
	{
		OnChargeDepleted.Broadcast();
	}

}