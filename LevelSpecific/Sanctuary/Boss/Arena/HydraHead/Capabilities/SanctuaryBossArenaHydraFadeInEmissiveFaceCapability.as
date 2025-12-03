class USanctuaryBossArenaHydraFadeInEmissiveFaceCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	ASanctuaryBossArenaHydraHead HydraHead;
	default TickGroup = EHazeTickGroup::Gameplay;

	float FadeInTimer = 0.0;
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
		if (HydraHead.ShouldHaveEmissiveFace())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (HydraHead.ShouldHaveEmissiveFace())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FadeInTimer = 0.0;
		HydraHead.EmissiveFaceFadeInCurve.GetTimeRange(MinTime, MaxTime);
		if (HydraHead.AccEmissiveFace.Value > KINDA_SMALL_NUMBER)
		{
			const float ArtificalTimeStep = 1.0 / 60.0;
			bool bSearch = true;
			while (bSearch)
			{
				if (HydraHead.EmissiveFaceFadeInCurve.GetFloatValue(FadeInTimer) > HydraHead.AccEmissiveFace.Value)
				{
					bSearch = false;
					break;
				}
				if (FadeInTimer >= MaxTime)
				{
					bSearch = false;
					break;
				}
				FadeInTimer += ArtificalTimeStep;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FadeInTimer += DeltaTime;
		FadeInTimer = Math::Clamp(FadeInTimer, 0.0, MaxTime);

		float Target = HydraHead.EmissiveFaceFadeInCurve.GetFloatValue(FadeInTimer);
		HydraHead.AccEmissiveFace.AccelerateTo(Target, 0.05, DeltaTime);

		HydraHead.EmissiveFaceDynamicMaterial.SetVectorParameterValue(n"EmissiveTintMaw", FLinearColor::White * HydraHead.AccEmissiveFace.Value);
	}
};