class USanctuaryBossArenaSidescrollLockPlayerCapability : UHazePlayerCapability
{
	ASanctuaryBossArenaManager ArenaManager;
	ASanctuaryBossArenaHydra Hydra;
	UMedallionPlayerComponent MedallionComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MedallionComp = UMedallionPlayerComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (ArenaManager == nullptr)
			return false;
		if (Hydra == nullptr)
			return false;
		if (Hydra.KillCount >= CompanionAviation::HeadsToKill)
			return false;
		if (Player.IsAnyCapabilityActive(AviationCapabilityTags::Aviation))
			return false;
		if (MedallionComp.IsMedallionCoopFlying())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Player.IsAnyCapabilityActive(AviationCapabilityTags::Aviation))
			return true;
		if (Hydra.KillCount >= CompanionAviation::HeadsToKill)
			return true;
		if (MedallionComp.IsMedallionCoopFlying())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		TryCacheThings();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (ArenaManager.SidescrollingZone != nullptr)
			ArenaManager.SidescrollingZone.EnableForPlayer(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (ArenaManager.SidescrollingZone != nullptr)
			ArenaManager.SidescrollingZone.DisableForPlayer(Player, this);
		//PrintToScreen("Disabled sidescrolling move for " + Player.GetName());
	}

	void TryCacheThings() 
	{
		if (ArenaManager == nullptr)
		{
			TListedActors<ASanctuaryBossArenaManager> BossManagers;
			if (BossManagers.Num() == 1)
				ArenaManager = BossManagers[0];
		}
		if (Hydra == nullptr)
		{
			TListedActors<ASanctuaryBossArenaHydra> Hydras;
			if (Hydras.Num() == 1)
				Hydra = Hydras[0];
		}
	}
};

