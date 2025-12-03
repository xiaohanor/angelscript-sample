class UIslandRedBlueTargetingCapability : UHazePlayerCapability
{
	// Since we don't want the crosshair to be hidden even if we block weapons for a bit, we don't have the below tag
	//default CapabilityTags.Add(IslandRedBlueWeapon::IslandRedBlueWeapon);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(IslandRedBlueWeapon::IslandRedBlueEquipped);
	default CapabilityTags.Add(IslandRedBlueWeapon::IslandTargeting);

	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);

	default TickGroup = EHazeTickGroup::Input;

	UIslandRedBlueWeaponUserComponent WeaponUserComponent;
	UPlayerTargetablesComponent TargetContainerComponent;
	UPlayerAimingComponent AimComponent;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	FAimingSettings AimSettings;
	default AimSettings.bShowCrosshair = true;
	default AimSettings.bApplyAimingSensitivity = false;
	default AimSettings.bUseAutoAim = true;
	default AimSettings.bCrosshairFollowsTarget = true;
	default AimSettings.OverrideAutoAimTarget = UIslandRedBlueTargetableComponent;
	default AimSettings.bOverrideSnapOffsetPitch = true;

	FTargetableOutlineSettings OutlineSettings;
	default OutlineSettings.TargetableCategory = n"IslandRedBlueTargetable";
	default OutlineSettings.bOnlyShowOneTarget = true;

	FHazeAcceleratedVector AcceleratedAimDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeaponUserComponent = UIslandRedBlueWeaponUserComponent::Get(Player);
		TargetContainerComponent = UPlayerTargetablesComponent::Get(Player);
		AimComponent = UPlayerAimingComponent::Get(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);

		if(WeaponUserComponent.CrosshairWidget != nullptr)
			AimSettings.OverrideCrosshairWidget = WeaponUserComponent.CrosshairWidget;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WeaponUserComponent.HasEquippedWeapons())
			return false;

		if(AimComponent.IsAiming(WeaponUserComponent))
			return false;

		if(AimComponent.HasAiming2DConstraint())
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!WeaponUserComponent.HasEquippedWeapons())
			return true;

		if(AimComponent.HasAiming2DConstraint())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AimComponent.StartAiming(WeaponUserComponent, AimSettings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComponent.StopAiming(WeaponUserComponent);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHitResult Hit;
		FVector BulletTarget = WeaponUserComponent.GetBulletTargetLocation(Hit);

		FVector TargetDirection = (BulletTarget - Player.Mesh.GetSocketLocation(n"Spine2")).GetSafeNormal();

		if(ActiveDuration == 0.0)
			AcceleratedAimDirection.SnapTo(TargetDirection);
		else
			AcceleratedAimDirection.AccelerateTo(TargetDirection, 0.1, DeltaTime);

		WeaponUserComponent.WeaponAnimData.AimDirection = TargetDirection;

		// Show all the widgets for the current aiming
		//TargetContainerComponent.ShowWidgetsForTargetables(UIslandRedBlueTargetableComponent, WeaponUserComponent.DefaultAimWidget);

		if(WeaponUserComponent.bUseOutlines)
			TargetContainerComponent.ShowOutlinesForTargetables(OutlineSettings);
	}
};