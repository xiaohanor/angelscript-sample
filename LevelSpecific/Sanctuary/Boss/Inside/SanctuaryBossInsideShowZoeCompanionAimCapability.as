class USanctuaryBossInsideShowZoeCompanionAimCapability : UHazePlayerCapability
{
	UDarkPortalUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UDarkPortalUserComponent::Get(Owner);
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
		UserComp.bShowAimForOtherPlayer = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UserComp.bShowAimForOtherPlayer = false;
	}
};