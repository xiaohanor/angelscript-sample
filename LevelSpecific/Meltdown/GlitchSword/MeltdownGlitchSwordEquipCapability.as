class UMeltdownGlitchSwordEquipCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default TickGroup = EHazeTickGroup::Movement;

	UMeltdownGlitchSwordUserComponent SwordComp;
	UPlayerAimingComponent AimingComp;
	UMeltdownGlitchShootingUserComponent ShootingComp;
	UMeltdownGlitchShootingCrosshair Crosshair;

	bool bWeaponVisible = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwordComp = UMeltdownGlitchSwordUserComponent::Get(Player);
		AimingComp = UPlayerAimingComponent::Get(Player);
		ShootingComp = UMeltdownGlitchShootingUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!ShootingComp.bGlitchShootingActive)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!ShootingComp.bGlitchShootingActive)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SwordComp.Sword = SpawnActor(SwordComp.SwordClass);
		SwordComp.Sword.AttachToComponent(Player.Mesh, n"RightAttach");
		SwordComp.Sword.SetActorHiddenInGame(true);

		FAimingSettings AimingSettings;
		AimingSettings.bShowCrosshair = true;
		AimingSettings.OverrideCrosshairWidget = SwordComp.CrosshairClass;
		AimingSettings.bUseAutoAim = true;
		AimingSettings.bApplyAimingSensitivity = false;
		AimingComp.StartAiming(n"MeltdownGlitchSword", AimingSettings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SwordComp.Sword.DestroyActor();
		SwordComp.Sword = nullptr;
		AimingComp.StopAiming(n"MeltdownGlitchSword");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ShootingComp.WeaponVisibility.Get() != bWeaponVisible)
		{
			if (ShootingComp.WeaponVisibility.Get())
			{
				bWeaponVisible = true;
				if (IsValid(SwordComp.Sword))
					SwordComp.Sword.SetActorHiddenInGame(false);
			}
			else
			{
				bWeaponVisible = false;
				if (IsValid(SwordComp.Sword))
					SwordComp.Sword.SetActorHiddenInGame(true);
			}
		}
	}
};