class UMoonMarketSausageCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(PlayerMovementTags::AirMotion, this);
		Owner.BlockCapabilities(PlayerMovementTags::AirJump, this);
		Owner.BlockCapabilities(PlayerMovementTags::AirDash, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(PlayerMovementTags::AirMotion, this);
		Owner.UnblockCapabilities(PlayerMovementTags::AirJump, this);
		Owner.UnblockCapabilities(PlayerMovementTags::AirDash, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};