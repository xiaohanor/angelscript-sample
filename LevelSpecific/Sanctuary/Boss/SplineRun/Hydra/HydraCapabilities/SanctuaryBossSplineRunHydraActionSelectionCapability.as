class USanctuaryBossSplineRunHydraActionComponent : UActorComponent
{
	FHazeStructQueue Queue;
};

asset SanctuaryBossSplineRunHydraActionSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USanctuaryBossSplineRunHydraActionSelectionCapability);
	Capabilities.Add(USanctuaryBossSplineRunHydraActionNodeIdleCapability);
	Capabilities.Add(USanctuaryBossSplineRunHydraActionNodeShootProjectileCapability);
	Capabilities.Add(USanctuaryBossSplineRunHydraActionNodeWaveCapability);
};

class USanctuaryBossSplineRunHydraActionSelectionCapability : UHazeCapability
{
	default CapabilityTags.Add(ArenaHydraTags::SplineRunHydra);
	default CapabilityTags.Add(ArenaHydraTags::Action);
	ASanctuaryBossSplineRunHydra SplineRunHydra;
	USanctuaryBossSplineRunHydraActionComponent BossComp;

	bool bIsOnInterval = false;
	bool bDidShoot = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplineRunHydra = Cast<ASanctuaryBossSplineRunHydra>(Owner);
		BossComp = USanctuaryBossSplineRunHydraActionComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return ShouldBeActive();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	bool ShouldBeActive() const
	{	
		if (SanctuaryHydraDevToggles::NoAttacks.IsEnabled())
			return false;
		TListedActors<ASanctuaryBossArenaManager> Arenas;
		if (Arenas.Num() > 0) // Happens when we load in the stuff while in arena. These bois start shootin a bit too early
			return false;
		if (!HasControl())
			return false;
		if (!SplineRunHydra.bDoAttackLoop)
			return false;
		if (SplineRunHydra.Phase != ESanctuaryBossSplineRunHydraPhase::AttackLoop)
			return false;

		if (bIsOnInterval && DeactiveDuration < SplineRunHydra.SpawnInterval)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		bool bResetInterval = !SplineRunHydra.bDoAttackLoop || SplineRunHydra.Phase != ESanctuaryBossSplineRunHydraPhase::AttackLoop;
		if (bResetInterval)
			bIsOnInterval = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bIsOnInterval = true;
		Projectile();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// BossComp.Queue.Reset();
	}

	void Idle(float Duration)
	{
		FSanctuaryBossSplineRunHydraActionNodeIdleData Data;
		Data.Duration = Duration;
		BossComp.Queue.Queue(Data);
	}

	void Projectile()
	{
		FSanctuaryBossSplineRunHydraActionNodeShootProjectileData Data;
		BossComp.Queue.Queue(Data);
	}

	void Wave()
	{
		FSanctuaryBossSplineRunHydraActionNodeWaveData Data;
		BossComp.Queue.Queue(Data);
	}
}
