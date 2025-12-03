class UIslandRedBlueStickyGrenadeAimingCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Input;
	default CapabilityTags.Add(IslandRedBlueStickyGrenade::IslandRedBlueStickyGrenade);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	UPlayerAimingComponent AimComponent;
	UIslandRedBlueStickyGrenadeUserComponent GrenadeUserComp;

	FAimingSettings AimSettings;
	default AimSettings.bShowCrosshair = false;
	default AimSettings.bApplyAimingSensitivity = false;
	default AimSettings.bUseAutoAim = true;
	default AimSettings.bCrosshairFollowsTarget = false;
	default AimSettings.OverrideAutoAimTarget = UIslandRedBlueStickyGrenadeTargetable;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComponent = UPlayerAimingComponent::Get(Player);
		GrenadeUserComp = UIslandRedBlueStickyGrenadeUserComponent::Get(Player);
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
		AimComponent.StartAiming(GrenadeUserComp, AimSettings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComponent.StopAiming(GrenadeUserComp);
	}
}