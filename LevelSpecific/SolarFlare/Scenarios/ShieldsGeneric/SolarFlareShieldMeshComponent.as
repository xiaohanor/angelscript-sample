class USolarFlareShieldMeshComponent : UStaticMeshComponent
{
	UMaterialInstanceDynamic DynamicMat;

	float MaxFrames = 20.0;
	float Frame = 1.0;

	float FadeAlpha;
	float TargetRegenAlpha;
	float RegenAlpha = 0.0;

	private bool bOn;
	float ImpactTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FadeAlpha = 0.0;
		Frame = MaxFrames;
		DynamicMat = this.CreateDynamicMaterialInstance(0);
		DynamicMat.SetScalarParameterValue(n"Display Frame", Frame);
		DynamicMat.SetScalarParameterValue(n"Auto Playback", 0);
		DynamicMat.SetScalarParameterValue(n"OverallOpacity", FadeAlpha);
		DynamicMat.SetScalarParameterValue(n"RegenAlpha", RegenAlpha);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bOn)
		{
			FadeAlpha = Math::FInterpConstantTo(FadeAlpha, 1.0, DeltaSeconds, 2.5);
			RegenAlpha = Math::FInterpConstantTo(RegenAlpha, TargetRegenAlpha, DeltaSeconds, 0.5);
			// PrintToScreen(f"{RegenAlpha=}");
			// PrintToScreen(f"{Frame=}");
			// PrintToScreen(f"{FadeAlpha=}");
		}
		else
		{
			if (Frame < MaxFrames)
				Frame += MaxFrames * DeltaSeconds;

			Frame = Math::Clamp(Frame, 1, MaxFrames);
			// PrintToScreen(f"{Frame=}");
			// PrintToScreen(f"{RegenAlpha=}");

			if (ImpactTime > 0.0)
				ImpactTime -= DeltaSeconds;
			else
				FadeAlpha = Math::FInterpConstantTo(FadeAlpha, 0.0, DeltaSeconds, 3.5);
		}

		DynamicMat.SetScalarParameterValue(n"RegenAlpha", RegenAlpha);
		DynamicMat.SetScalarParameterValue(n"Display Frame", Frame);
		DynamicMat.SetScalarParameterValue(n"OverallOpacity", FadeAlpha);
	}

	void SetRegenAlphaDirect(float NewRegenAlpha)
	{
		RegenAlpha = NewRegenAlpha;
		TargetRegenAlpha = NewRegenAlpha;
		Print("SetRegenAlphaDirect: " + NewRegenAlpha);
	}

	void SetRegenAlphaTarget(float NewRegenAlpha)
	{
		TargetRegenAlpha = NewRegenAlpha;
	}

	void TurnOn()
	{
		bOn = true;
		SetRegenAlphaDirect(0);
		Frame = 1.0;
	}

	void TurnOff()
	{
		bOn = false;
	}

	void RunImpact()
	{
		ImpactTime = 1.0;
		bOn = false;
	}

	bool IsOn()
	{
		return bOn;
	}
};