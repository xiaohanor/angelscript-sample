event void FOnMeltdownGlitchinessMaxed();

class UMeltdownGlitchShootingAccumulationComponent : UActorComponent
{
	// How many glitch hits before we hit 100% glitch accumulation
	UPROPERTY(Category = "Glitch Accumulation")
	int MaxGlitchHits = 10;

	// How fast does our glitch accumulation decay over time?
	UPROPERTY(Category = "Glitch Accumulation")
	float GlitchinessPercentageDecay = 0.1;

	// Stop decaying the glitchiness when the maximum is reached
	UPROPERTY(Category = "Glitch Accumulation")
	bool bStopDecayWhenMaxed = true;

	// Event that is emitted when the glitchiness of the object reaches the maximum
	UPROPERTY()
	FOnMeltdownGlitchinessMaxed OnGlitchinessMaxed;

	private UMeltdownGlitchShootingResponseComponent ResponseComp;
	private float Glitchiness = 0.0;
	private bool bIsMaxed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp = UMeltdownGlitchShootingResponseComponent::GetOrCreate(Owner);
		ResponseComp.OnGlitchHit.AddUFunction(this, n"OnGlitchHit");
	}

	// Get the current glitchiness as a percentage from 0 to 1
	UFUNCTION(BlueprintPure)
	float GetCurrentGlitchiness() const
	{
		return Glitchiness;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		PrintToScreen(f"{Glitchiness=}");
		if (GlitchinessPercentageDecay > 0.0 && Glitchiness > 0.0 && (!bIsMaxed || !bStopDecayWhenMaxed))
		{
			Glitchiness = Math::Max(Glitchiness - GlitchinessPercentageDecay * DeltaSeconds, 0.0);
		}
		else
		{
			SetComponentTickEnabled(false);
		}
	}

	UFUNCTION()
	private void OnGlitchHit(FMeltdownGlitchImpact Impact)
	{
		Glitchiness += 1.0 / Math::Max(MaxGlitchHits, 0.001);
		if (Glitchiness >= 1.0)
		{
			if (!bIsMaxed)
			{
				OnGlitchinessMaxed.Broadcast();
				bIsMaxed = true;
			}
		}

		if (GlitchinessPercentageDecay > 0.0 && Glitchiness > 0.0 && (!bIsMaxed || !bStopDecayWhenMaxed))
			SetComponentTickEnabled(true);
	}
};