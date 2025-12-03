struct FGameShowPlayerRespawnBlockActivationParams
{
	AGameShowArenaBomb ActiveBomb;
}

class UGameShowArenaPlayerRespawnBlockCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	bool bHasBlockedRespawn = false;

	AGameShowArenaBomb RelevantBomb;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGameShowPlayerRespawnBlockActivationParams& Params) const
	{
		auto Bomb = GameShowArena::GetClosestEnabledBombToLocation(Player.ActorLocation);
		if (Bomb == nullptr)
			return false;

		bool bShouldBlockRespawn = false;

		if (Bomb.TimeUntilExplosion <= 2)
			bShouldBlockRespawn = true;

		if (Bomb.State.Get() == EGameShowArenaBombState::Thrown)
			bShouldBlockRespawn = true;

		if (Bomb.State.Get() == EGameShowArenaBombState::Exploding)
			bShouldBlockRespawn = true;

		if (bShouldBlockRespawn)
		{
			Params.ActiveBomb = Bomb;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (RelevantBomb.State.Get() == EGameShowArenaBombState::Frozen)
			return true;

		if (RelevantBomb.State.Get() == EGameShowArenaBombState::Disposed)
			return true;

		if (RelevantBomb.State.Get() == EGameShowArenaBombState::Caught)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGameShowPlayerRespawnBlockActivationParams Params)
	{
		Player.BlockCapabilities(n"Respawn", this);
		bHasBlockedRespawn = true;
		RelevantBomb = Params.ActiveBomb;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(n"Respawn", this);
		bHasBlockedRespawn = false;
	}
};