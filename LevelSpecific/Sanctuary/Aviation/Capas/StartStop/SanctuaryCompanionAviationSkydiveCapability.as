class USanctuaryCompanionAviationSkydiveCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerMovementComponent PlayerMove;
	USanctuaryCompanionAviationPlayerComponent AviationComp;
	ASanctuaryBossArenaManager ArenaManager;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerMove = UPlayerMovementComponent::Get(Player);
		AviationComp = USanctuaryCompanionAviationPlayerComponent::Get(Player);
		TListedActors<ASanctuaryBossArenaManager> BossManagers;
		if (BossManagers.Num() == 1)
			ArenaManager = BossManagers[0];
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Player.IsPlayerDead())
			return false;
		if (PlayerMove.IsOnAnyGround())
			return false;
		if (AviationComp.AviationState != EAviationState::Skydive)
			return false;
		if (ArenaManager == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Player.IsPlayerDead())
			return true;
		if (PlayerMove.IsOnAnyGround())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.EnableSkydive(this, EPlayerSkydiveMode::Default, EPlayerSkydiveStyle::Falling, EInstigatePriority::Normal, ArenaManager.SkydiveSettings, EHazeSettingsPriority::Gameplay);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AviationComp.SetAviationState(EAviationState::None);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.DisableSkydive(this);
	}
};