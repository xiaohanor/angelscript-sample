class USteerSandFishPlayerCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Desert::GetDesertLevelState() != EDesertLevelState::Steer)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Desert::GetDesertLevelState() != EDesertLevelState::Steer)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		//Player.BlockCapabilities(ArenaSandFish::PlayerTags::ArenaSandFishHitPlayer, this);
		Player.BlockCapabilities(n"Death", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		//Player.UnblockCapabilities(ArenaSandFish::PlayerTags::ArenaSandFishHitPlayer, this);
		Player.UnblockCapabilities(n"Death", this);
	}
};