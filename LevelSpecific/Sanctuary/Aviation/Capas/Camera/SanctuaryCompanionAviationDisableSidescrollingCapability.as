
class USanctuaryCompanionAviationDisableSidescrollingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AviationCapabilityTags::Aviation);
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USanctuaryCompanionAviationPlayerComponent AviationComp;
	ASanctuaryBossArenaManager ArenaManager;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
		TListedActors<ASanctuaryBossArenaManager> BossManagers;
		if (BossManagers.Num() == 1)
			ArenaManager = BossManagers[0];
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!AviationComp.HasDestination())
			return false;

		if (!Player.IsAnyCapabilityActive(AviationCapabilityTags::Aviation))
			return false;

		if (ArenaManager == nullptr)
			return false;

		const FSanctuaryCompanionAviationDestinationData& DestinationData = AviationComp.GetNextDestination();
		if (!DestinationData.bDisableSidescroll)
			return false;

		return false; // capa not used! sidescroller camera always exist at low prio
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!AviationComp.HasDestination())
			return true;

		if (!Player.IsAnyCapabilityActive(AviationCapabilityTags::Aviation))
			return true;

		const FSanctuaryCompanionAviationDestinationData& DestinationData = AviationComp.GetNextDestination();
		if (!DestinationData.bDisableSidescroll)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Timer::SetTimer(this, n"DelayedDeactivation", 1.5);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ArenaManager.EnableSidescrollingCamera(Player, true);
	}

	UFUNCTION()
	private void DelayedDeactivation()
		{
		if (ArenaManager != nullptr)
			ArenaManager.EnableSidescrollingCamera(Player, false);
	}
};

