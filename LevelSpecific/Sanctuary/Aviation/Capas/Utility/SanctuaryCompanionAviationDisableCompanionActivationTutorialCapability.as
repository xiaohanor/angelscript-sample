class USanctuaryCompanionAviationDisableCompanionActivationTutorialCapability : UHazePlayerCapability
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Player.IsAnyCapabilityActive(AviationCapabilityTags::Aviation))
			return true;
		return false;
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

