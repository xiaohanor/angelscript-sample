


class UScifiPlayerCopsGunPassiveCrosshairCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"CopsGun");
	default CapabilityTags.Add(BlockedWhileIn::Swimming);

	default DebugCategory = n"CopsGun";

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UScifiPlayerCopsGunManagerComponent Manager;
	UPlayerAimingComponent AimingComp;

	UScifiPlayerCopsGunSettings Settings;
	UScifiCopsGunCrosshair CrosshairWidget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = UScifiPlayerCopsGunManagerComponent::Get(Player);
		AimingComp = UPlayerAimingComponent::Get(Player);
		Settings = Manager.Settings;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Settings.ThrowInputType != EScifiPlayerCopsGunThrowType::ThrowOnAimPress)
			return false;

		if(Manager.bPlayerWantsToShootWeapon)
			return false;

		if(Manager.bPlayerWantsToThrowWeapon)
			return false;

		if(Manager.bTurretIsActive)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FScifiPlayerCopsGunWeaponTarget& DeactivationParams) const
	{
		if(Settings.ThrowInputType != EScifiPlayerCopsGunThrowType::ThrowOnAimPress)
			return true;

		if(Manager.bPlayerWantsToShootWeapon)
			return true;

		if(Manager.bPlayerWantsToThrowWeapon)
			return true;

		if(Manager.bTurretIsActive)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FAimingSettings PassiveAimSettings = Manager.AimSettings;
		PassiveAimSettings.bShowCrosshair = true;
		PassiveAimSettings.bApplyAimingSensitivity = false;
		AimingComp.StartAiming(this, PassiveAimSettings);
		CrosshairWidget = Cast<UScifiCopsGunCrosshair>(AimingComp.GetCrosshairWidget(this));
		CrosshairWidget.bAiming = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FScifiPlayerCopsGunWeaponTarget DeactivationParams)
	{	
		AimingComp.StopAiming(this);
		CrosshairWidget = nullptr;
	}
		
};