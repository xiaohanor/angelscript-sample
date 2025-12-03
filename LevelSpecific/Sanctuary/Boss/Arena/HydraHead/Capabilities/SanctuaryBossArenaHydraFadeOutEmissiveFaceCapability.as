class USanctuaryBossArenaHydraFadeOutEmissiveFaceCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	ASanctuaryBossArenaHydraHead HydraHead;
	default TickGroup = EHazeTickGroup::Gameplay;

	float FadeOutTimer = 0.0;
	float MinTime = 0.0;
	float MaxTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HydraHead = Cast<ASanctuaryBossArenaHydraHead>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HydraHead.ShouldHaveEmissiveFace())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!HydraHead.ShouldHaveEmissiveFace())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FadeOutTimer = 0.0;
		HydraHead.EmissiveFaceFadeOutCurve.GetTimeRange(MinTime, MaxTime);
		if (HydraHead.AccEmissiveFace.Value > KINDA_SMALL_NUMBER)
		{
			const float ArtificalTimeStep = 1.0 / 60.0;
			bool bSearch = true;
			while (bSearch)
			{
				if (HydraHead.EmissiveFaceFadeOutCurve.GetFloatValue(FadeOutTimer) > HydraHead.AccEmissiveFace.Value)
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

		float Target = HydraHead.EmissiveFaceFadeOutCurve.GetFloatValue(FadeOutTimer);
		HydraHead.AccEmissiveFace.AccelerateTo(Target, 0.05, DeltaTime);

		HydraHead.EmissiveFaceDynamicMaterial.SetVectorParameterValue(n"EmissiveTintMaw", FLinearColor::White * HydraHead.AccEmissiveFace.Value);
	}
};