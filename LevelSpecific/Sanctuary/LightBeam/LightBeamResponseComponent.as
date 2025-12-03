event void FLightBeamHitSignature(AHazePlayerCharacter Instigator);
event void FLightBeamFullyChargedSignature();
event void FLightBeamChargeResetSignature();

class ULightBeamResponseComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	// Charge required until fully charged.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response")
	float ChargeTime = 1.0;

	// Modifies the charge power, where 1.0 is equal to delta time.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response")
	float ChargeMultiplier = 1.0;

	// Modifies the charge decay, where 1.0 is equal to delta time.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response")
	float DecayMultiplier = 1.0;
	
	// Delay before charge starts depleting.
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Response")
	float DecayDelay = 0.6;

	UPROPERTY(NotEditable, BlueprintReadOnly, Category = "Response")
	float CurrentCharge;

	UPROPERTY(Category = "Response")
	FLightBeamHitSignature OnHitBegin;
	UPROPERTY(Category = "Response")
	FLightBeamHitSignature OnHitEnd;
	UPROPERTY(Category = "Response")
	FLightBeamFullyChargedSignature OnFullyCharged;
	UPROPERTY(Category = "Response")
	FLightBeamChargeResetSignature OnChargeReset;

	TArray<AHazePlayerCharacter> Beamers;

	private float DecayTimestamp;
	private bool bChargeEventTriggered;

	void HitBegin(AHazePlayerCharacter Beamer)
	{
		Beamers.AddUnique(Beamer);
		OnHitBegin.Broadcast(Beamer);

		SetComponentTickEnabled(true);
	}

	void HitEnd(AHazePlayerCharacter Beamer)
	{
		Beamers.RemoveSingleSwap(Beamer);
		OnHitEnd.Broadcast(Beamer);

		DecayTimestamp = Time::GameTimeSeconds;
	}

	void FullyCharged()
	{
		OnFullyCharged.Broadcast();
	}

	void ChargeReset()
	{
		OnChargeReset.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Beamers.Num() != 0)
		{
			CurrentCharge = Math::Min(CurrentCharge + DeltaTime * ChargeMultiplier, ChargeTime);
		}
		else
		{
			if (Time::GetGameTimeSince(DecayTimestamp) >= DecayDelay)
				CurrentCharge = Math::Max(CurrentCharge - DeltaTime * DecayMultiplier, 0.0);
		}

		if (!bChargeEventTriggered && CurrentCharge >= ChargeTime)
		{
			OnFullyCharged.Broadcast();
			bChargeEventTriggered = true;
		}

		if (Math::IsNearlyZero(CurrentCharge) && Beamers.Num() == 0)
		{
			CurrentCharge = 0.0;
			bChargeEventTriggered = false;
			ChargeReset();
			SetComponentTickEnabled(false);
		}
	}

	UFUNCTION(BlueprintPure)
	float GetChargeAlpha() const property
	{
		return Math::Saturate(CurrentCharge / ChargeTime);
	}
}