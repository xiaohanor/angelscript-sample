struct FSanctuaryBossArenaHydraProjectileActionData
{
	ESanctuaryBossArenaHydraHead Head;
}

class USanctuaryBossArenaHydraActionProjectileCapability : UHazeCapability
{
	FSanctuaryBossArenaHydraProjectileActionData Params;
	default CapabilityTags.Add(ArenaHydraTags::ArenaHydra);
	default CapabilityTags.Add(ArenaHydraTags::Action);
	ASanctuaryBossArenaHydra Hydra;
	USanctuaryBossArenaHydraActionsComponent BossComp;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Hydra = Cast<ASanctuaryBossArenaHydra>(Owner);
		BossComp = USanctuaryBossArenaHydraActionsComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryBossArenaHydraProjectileActionData& ActivationParams) const
	{
		if (BossComp.ActionQueue.Start(this, ActivationParams))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryBossArenaHydraProjectileActionData ActivationParams)
	{
		Params = ActivationParams;
		if (BossComp.bDebugPrintActions)
			Print("Arena Hydra Boss Action");
		for (auto Head : Hydra.HydraHeads)
		{
			if (Head.HeadID == Params.Head)
			{
				if (!Head.CanDoProjectile())
				{
					if (Head.LaneBuddy != nullptr && Head.LaneBuddy.CanDoProjectile())
						Head.LaneBuddy.ProjectileAttack();
				}
				else
				{
					Head.ProjectileAttack();
				}
				break;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossComp.ActionQueue.Finish(this);
	}
}
