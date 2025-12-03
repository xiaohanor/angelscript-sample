class USanctuaryCompanionAviationDisableCompanionActivationCapability : UHazePlayerCapability
{
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
		Player.BlockCapabilities(LightBird::Tags::LightBirdAim, this);
		Player.BlockCapabilities(DarkPortal::Tags::DarkPortalAim, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(LightBird::Tags::LightBirdAim, this);
		Player.UnblockCapabilities(DarkPortal::Tags::DarkPortalAim, this);
	}
};

