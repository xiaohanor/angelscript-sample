class UGravityBikeBladeActiveCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::AfterGameplay;

	UGravityBikeBladePlayerComponent BladeComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BladeComp = UGravityBikeBladePlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!BladeComp.IsThrowingOrThrown() && !BladeComp.IsGrappling())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!BladeComp.IsThrowingOrThrown() && !BladeComp.IsGrappling())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Disable dying while grappling
		Player.BlockCapabilities(CapabilityTags::Death, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Death, this);
	}
};