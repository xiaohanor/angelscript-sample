class UDarkProjectileAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(DarkProjectile::Tags::DarkProjectile);
	default CapabilityTags.Add(DarkProjectile::Tags::DarkProjectileAim);

	default TickGroupOrder = 130;

	UDarkProjectileUserComponent UserComp;
	UPlayerAimingComponent AimComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UDarkProjectileUserComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (UserComp.ChargedProjectiles.Num() > 0)
			return false;

		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Wait for charged projectiles to be launched before exiting
		if (!IsActioning(ActionNames::PrimaryLevelAbility))
		{
			if (UserComp.ChargedProjectiles.Num() == 0)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FAimingSettings AimSettings;
		AimSettings.bShowCrosshair = true;
		AimSettings.OverrideAutoAimTarget = UDarkProjectileTargetComponent;
		AimComp.StartAiming(UserComp, AimSettings);

		Player.BlockCapabilities(DarkPortal::Tags::DarkPortal, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.StopAiming(UserComp);
		
		Player.UnblockCapabilities(DarkPortal::Tags::DarkPortal, this);
	}
}