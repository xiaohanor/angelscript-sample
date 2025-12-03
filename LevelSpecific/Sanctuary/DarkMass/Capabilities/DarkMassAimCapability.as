class UDarkMassAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(DarkMass::Tags::DarkMass);
	default CapabilityTags.Add(DarkMass::Tags::DarkMassAim);
	
	default DebugCategory = DarkMass::Tags::DarkMass;

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 50;

	UDarkMassUserComponent UserComp;
	UPlayerAimingComponent AimComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UDarkMassUserComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!IsActioning(ActionNames::SecondaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsActioning(ActionNames::SecondaryLevelAbility))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Only used for crosshair (?)
		FAimingSettings AimSettings;
		AimSettings.bShowCrosshair = true;
		AimComp.StartAiming(UserComp, AimSettings);

		Player.EnableStrafe(this);
		Player.BlockCapabilities(DarkProjectile::Tags::DarkProjectile, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.StopAiming(UserComp);

		Player.DisableStrafe(this);
		Player.UnblockCapabilities(DarkProjectile::Tags::DarkProjectile, this);
	}
}