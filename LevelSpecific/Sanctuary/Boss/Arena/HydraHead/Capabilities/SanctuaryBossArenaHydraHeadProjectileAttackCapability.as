class USanctuaryBossArenaHydraHeadProjectileAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(ArenaHydraTags::HydraProjectile);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASanctuaryBossArenaHydraHead HydraHead;

	bool bProjectileLaunched = false;

	int ProjectilesToLaunch;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HydraHead = Cast<ASanctuaryBossArenaHydraHead>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HydraHead.GetReadableState().bShouldLaunchProjectile)
			return false;

		// make sure local is set to synced state, so we don't activate twice :)
		if (DeactiveDuration < Network::GetPingRoundtripSeconds() * 4.0) 
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > HydraHead.Settings.ArenaProjectileAttackDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bProjectileLaunched = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HydraHead.LocalHeadState.bShouldLaunchProjectile = false;
		HydraHead.AttackPitch = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bProjectileLaunched && ActiveDuration > HydraHead.Settings.ArenaProjectileAnticipationDuration)
		{
			ProjectilesToLaunch = 3;
			bProjectileLaunched = true;
			HydraHead.LaunchProjectile();

			//Timer::SetTimer(this, n"LaunchAdditionalProjectile", 0.2, true);
		}
		if (HydraHead.Settings.ArenaProjectileAttackDuration <= KINDA_SMALL_NUMBER)
			return;

		float Alpha = ActiveDuration / HydraHead.Settings.ArenaProjectileAttackDuration;
		HydraHead.AttackPitch = Math::Sin(Alpha * PI) * -50.0;
	}

	UFUNCTION()
	private void LaunchAdditionalProjectile()
	{
		ProjectilesToLaunch--;

		if (ProjectilesToLaunch <= 0)
		{
			Timer::ClearTimer(this, n"LaunchAdditionalProjectile");
			return;
		}
		

		HydraHead.LaunchProjectile();
	}
};