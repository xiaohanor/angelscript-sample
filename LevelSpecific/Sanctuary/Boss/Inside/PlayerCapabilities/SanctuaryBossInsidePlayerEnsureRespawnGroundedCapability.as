class USanctuaryBossInsidePlayerEnsureRespawnGroundedCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	USanctuaryBossInsidePlayerEnsureRespawnGroundedComponent Comp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Comp = USanctuaryBossInsidePlayerEnsureRespawnGroundedComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl())
			return false;
		if (!Player.IsPlayerDead())
			return false;
		if (Player.OtherPlayer.IsOnWalkableGround())
			return false;
		if (Comp.EnsureRequesters.Num() == 0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Player.IsPlayerDead())
			return true;
		if (Player.OtherPlayer.IsOnWalkableGround())
			return true;
		if (Comp.EnsureRequesters.Num() == 0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(n"Respawn", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(n"Respawn", this);
	}
};