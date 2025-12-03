class UCoastShoulderTurretCannonReloadCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	ACoastShoulderTurret Turret;

	UCoastShoulderTurretComponent TurretComp;
	UCoastShoulderTurretCannonAmmoComponent AmmoComp;

	UCoastShoulderTurretCannonSettings CannonSettings;

	float ReloadTimer = 0.0;

	bool bFullReload = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TurretComp = UCoastShoulderTurretComponent::Get(Player);
		AmmoComp = UCoastShoulderTurretCannonAmmoComponent::Get(Player);

		Turret = TurretComp.Turret;

		CannonSettings = UCoastShoulderTurretCannonSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Turret.IsShooting())
			return false;

		if(IsActioning(ActionNames::PrimaryLevelAbility))
			return false;

		if(AmmoComp.CurrentAmmoCount >= CannonSettings.MaxAmmoCount)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Turret.IsShooting())
			return true;

		if(!bFullReload
		&& IsActioning(ActionNames::PrimaryLevelAbility))
			return true;

		if(AmmoComp.CurrentAmmoCount >= CannonSettings.MaxAmmoCount)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ReloadTimer = 0.0;

		bFullReload = AmmoComp.CurrentAmmoCount <= 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ReloadTimer += DeltaTime;

		if(HasControl())
		{
			if(bFullReload)
			{
				if(ReloadTimer >= CannonSettings.ShotReloadTime * CannonSettings.MaxAmmoCount * CannonSettings.FullReloadTimeMultiplier)
				{
					CrumbRecoverAmmo(true);
				}
			}
			else
			{
				if(ReloadTimer >= CannonSettings.ShotReloadTime)
				{
					CrumbRecoverAmmo(false);
				}
			}
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbRecoverAmmo(bool bIsFullReload)
	{
		if(bIsFullReload)
		{
			AmmoComp.ChangeAmmo(CannonSettings.MaxAmmoCount);
			ReloadTimer -= CannonSettings.ShotReloadTime * CannonSettings.MaxAmmoCount * CannonSettings.FullReloadTimeMultiplier;
		}
		else
		{
			AmmoComp.ChangeAmmo(AmmoComp.CurrentAmmoCount + 1);
			ReloadTimer -= CannonSettings.ShotReloadTime;
		}
	}
};