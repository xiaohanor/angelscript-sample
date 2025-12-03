class USanctuaryBossSplineRunHydraFadeOutEmissiveFaceCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	ASanctuaryBossSplineRunHydra Hydra;
	default TickGroup = EHazeTickGroup::Gameplay;

	float FadeOutTimer = 0.0;
	float MinTime = 0.0;
	float MaxTime = 0.0;

	bool bSentStopEvent = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Hydra = Cast<ASanctuaryBossSplineRunHydra>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Hydra.ShouldHaveEmissiveFace())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Hydra.ShouldHaveEmissiveFace())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bSentStopEvent = false;
		FadeOutTimer = 0.0;
		Hydra.EmissiveFaceFadeOutCurve.GetTimeRange(MinTime, MaxTime);
		if (Hydra.AccEmissiveFace.Value > KINDA_SMALL_NUMBER)
		{
			const float ArtificalTimeStep = 1.0 / 60.0;
			bool bSearch = true;
			while (bSearch)
			{
				if (Hydra.EmissiveFaceFadeOutCurve.GetFloatValue(FadeOutTimer) > Hydra.AccEmissiveFace.Value)
				{
					bSearch = false;
					break;
				}
				if (FadeOutTimer >= MaxTime)
				{
					bSearch = false;
					break;
				}
				FadeOutTimer += ArtificalTimeStep;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FadeOutTimer += DeltaTime;
		FadeOutTimer = Math::Clamp(FadeOutTimer, 0.0, MaxTime);

		float Target = Hydra.EmissiveFaceFadeOutCurve.GetFloatValue(FadeOutTimer);
		Hydra.AccEmissiveFace.AccelerateTo(Target, 0.05, DeltaTime);

		Hydra.EmissiveFaceDynamicMaterial.SetVectorParameterValue(n"EmissiveTintMaw", FLinearColor::White * Hydra.AccEmissiveFace.Value);
		if (!bSentStopEvent && FadeOutTimer >= MaxTime - KINDA_SMALL_NUMBER)
		{
			bSentStopEvent = true;
			USanctuaryBossSplineRunHydraEventHandler::Trigger_Stop_GlowThroat(Owner);
		}
	}
};