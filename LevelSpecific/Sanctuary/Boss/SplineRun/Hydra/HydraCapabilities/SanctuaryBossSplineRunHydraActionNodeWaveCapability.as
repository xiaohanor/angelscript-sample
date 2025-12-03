struct FSanctuaryBossSplineRunHydraActionNodeWaveData
{
}

class USanctuaryBossSplineRunHydraActionNodeWaveCapability : UHazeCapability
{
	FSanctuaryBossSplineRunHydraActionNodeWaveData Params;
	default CapabilityTags.Add(ArenaHydraTags::SplineRunHydra);
	default CapabilityTags.Add(ArenaHydraTags::Action);
	USanctuaryBossSplineRunHydraActionComponent BossComp;
	ASanctuaryBossSplineRunHydra HydraOwner;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HydraOwner = Cast<ASanctuaryBossSplineRunHydra>(Owner);
		BossComp = USanctuaryBossSplineRunHydraActionComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryBossSplineRunHydraActionNodeWaveData& ActivationParams) const
	{
		if (BossComp.Queue.Start(this, ActivationParams))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration < 10.0) // ish animation duration
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryBossSplineRunHydraActionNodeWaveData ActivationParams)
	{
		Params = ActivationParams;

		HydraOwner.DesiredAnimation = ESanctuaryBossSplineRunHydraAnimation::Wave;
		// Timer::SetTimer(this, n"DelayedWave", 0.7);
		DelayedWave();
	}

	UFUNCTION()
	void DelayedWave()
	{
		TListedActors<ASanctuaryBossSplineRunWave> Waves;
		for (auto Wave : Waves)
		{
			if (!Wave.bIsWaveActive)
				Wave.StartWave();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossComp.Queue.Finish(this);
	}
}
