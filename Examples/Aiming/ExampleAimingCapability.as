
/**
 * Example capability that puts the player in aiming mode
 * while pressing right mouse / left trigger, and implements
 * an auto-aiming target.
 */
class UExampleAimingCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerAimingComponent AimingComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimingComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (IsActioning(ActionNames::SecondaryLevelAbility))
			return true;
		return false;
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
		FAimingSettings AimingSettings;
		AimingSettings.bShowCrosshair = true;
		AimingSettings.bUseAutoAim = true;
		AimingSettings.OverrideAutoAimTarget = UExampleAimingAutoTarget;
		AimingComp.StartAiming(this, AimingSettings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimingComp.StopAiming(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FAimingResult CurrentAim = AimingComp.GetAimingTarget(this);
		PrintToScreen("Direction: "+CurrentAim.AimDirection);

		if (CurrentAim.AutoAimTarget != nullptr)
			PrintToScreen("Aim Target: "+CurrentAim.AutoAimTarget);
	}
}