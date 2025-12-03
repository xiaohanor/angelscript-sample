class USanctuaryCompanionAviationSwoopBackCapability : UHazePlayerCapability
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

		if (!AviationComp.GetIsAviationActive())
			return false;

		if (AviationComp.AviationState != EAviationState::SwoopingBack)
			return false;

		return false; // disabled for now
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!AviationComp.GetIsAviationActive())
			return true;

		bool IsValid = AviationComp.AviationState == EAviationState::SwoopingBack || AviationComp.AviationState == EAviationState::Entry;
		if (!IsValid)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (ArenaManager != nullptr)
			ArenaManager.EnableSwoopbackCamera(Player, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Timer::SetTimer(this, n"DelayedDeactivation", 1.5);
	}

	UFUNCTION()
	private void DelayedDeactivation()
	{
		if (ArenaManager != nullptr)
			ArenaManager.EnableSwoopbackCamera(Player, false);
	}
};