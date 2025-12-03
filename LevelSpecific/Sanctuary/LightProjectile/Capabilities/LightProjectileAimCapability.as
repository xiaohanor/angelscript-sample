class ULightProjectileAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(LightProjectile::Tags::LightProjectile);
	default CapabilityTags.Add(LightProjectile::Tags::LightProjectileAim);

	default TickGroupOrder = 88;

	ULightProjectileUserComponent UserComp;
	UPlayerAimingComponent AimComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = ULightProjectileUserComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (UserComp.ChargedProjectiles.Num() > 0)
			return false;

		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Wait for charged projectiles to be launched
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
		AimSettings.OverrideAutoAimTarget = ULightProjectileTargetComponent;

		AimComp.StartAiming(UserComp, AimSettings);
		Player.BlockCapabilities(LightBeam::Tags::LightBeam, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.StopAiming(UserComp);
		Player.UnblockCapabilities(LightBeam::Tags::LightBeam, this);
	}
}