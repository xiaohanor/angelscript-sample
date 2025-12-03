class UIslandRedBlueForceTargetCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(IslandRedBlueWeapon::IslandRedBlueEquipped);

	default TickGroup = EHazeTickGroup::Input;

	UIslandRedBlueWeaponUserComponent WeaponUserComponent;
	UPlayerTargetablesComponent TargetContainerComponent;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	FHazeAcceleratedVector AcceleratedAimDirection;
	FTargetableOutlineSettings OutlineSettings;
	default OutlineSettings.TargetableCategory = n"IslandRedBlueTargetable";
	default OutlineSettings.bOnlyShowOneTarget = true;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WeaponUserComponent = UIslandRedBlueWeaponUserComponent::Get(Player);
		TargetContainerComponent = UPlayerTargetablesComponent::Get(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WeaponUserComponent.HasEquippedWeapons())
			return false;

		if(PerspectiveModeComp.PerspectiveMode == EPlayerMovementPerspectiveMode::SideScroller)
			return false;

		if(!WeaponUserComponent.HasForcedTarget())
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!WeaponUserComponent.HasEquippedWeapons())
			return true;

		if(PerspectiveModeComp.PerspectiveMode == EPlayerMovementPerspectiveMode::SideScroller)
			return true;

		if(!WeaponUserComponent.HasForcedTarget())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(IslandRedBlueWeapon::IslandTargeting, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(IslandRedBlueWeapon::IslandTargeting, this);
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
}