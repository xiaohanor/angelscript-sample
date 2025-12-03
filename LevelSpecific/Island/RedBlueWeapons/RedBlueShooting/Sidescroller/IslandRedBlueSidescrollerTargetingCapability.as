class UIslandRedBlueSidescrollerTargetingCapability : UHazePlayerCapability
{
	// Since we don't want the crosshair to be hidden even if we block weapons for a bit, we don't have the below tag
	//default CapabilityTags.Add(IslandRedBlueWeapon::IslandRedBlueWeapon);
	default CapabilityTags.Add(IslandRedBlueWeapon::IslandRedBlueEquipped);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 90;

	UIslandRedBlueSidescrollerWeaponUserComponent SidescrollerWeaponUserComponent;
	UIslandRedBlueWeaponUserComponent WeaponUserComponent;
	UPlayerTargetablesComponent TargetContainerComponent;
	UPlayerAimingComponent AimComponent;

	FAimingSettings AimSettings;
	default AimSettings.bShowCrosshair = true;
	default AimSettings.bApplyAimingSensitivity = false;
	default AimSettings.bUseAutoAim = false;
	default AimSettings.bCrosshairFollowsTarget = true;
	default AimSettings.OverrideAutoAimTarget = UIslandRedBlueTargetableComponent;
	default AimSettings.Crosshair2DSettings.DirectionalArrowSize = 0.0;

	FTargetableOutlineSettings OutlineSettings;
	default OutlineSettings.TargetableCategory = n"IslandRedBlueTargetable";
	default OutlineSettings.bOnlyShowOneTarget = true;

	FHazeAcceleratedVector AcceleratedAimDirection;

	private TArray<FVector> ValidAimDirections;
	private bool bCurrentUsingAutoAim = true;
	private bool bForceExit = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SidescrollerWeaponUserComponent = UIslandRedBlueSidescrollerWeaponUserComponent::Get(Player);
		WeaponUserComponent = UIslandRedBlueWeaponUserComponent::Get(Player);
		TargetContainerComponent = UPlayerTargetablesComponent::Get(Player);
		AimComponent = UPlayerAimingComponent::Get(Player);

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

		if(!AimComponent.HasAiming2DConstraint())
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!WeaponUserComponent.HasEquippedWeapons())
			return true;

		if(!AimComponent.HasAiming2DConstraint())
			return true;

		if(bForceExit)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(AimComponent.GetCurrentAimingConstraintType() == EAimingConstraintType2D::Spline)
			SetupValidAimDirections();

		AimComponent.StartAiming(WeaponUserComponent, AimSettings);
		bCurrentUsingAutoAim = AimSettings.bUseAutoAim;
		FVector TargetDirection = AimComponent.GetAimingTarget(WeaponUserComponent).AimDirection;
		AcceleratedAimDirection.SnapTo(TargetDirection);
		bForceExit = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComponent.ClearAimingRayOverride(this);
		AimComponent.StopAiming(WeaponUserComponent);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bCurrentUsingAutoAim != !SidescrollerWeaponUserComponent.bUseNew8DirectionAiming)
		{
			// Temp way to add dev input to change to use auto aim or not (force exit this capability to stop aiming and then start aiming again!)
			AimSettings.bUseAutoAim = !SidescrollerWeaponUserComponent.bUseNew8DirectionAiming;
			bForceExit = true;
			return;
		}

		if(SidescrollerWeaponUserComponent.bUseNew8DirectionAiming &&
			AimComponent.GetCurrentAimingConstraintType() == EAimingConstraintType2D::Spline)
			ConstrainAimToValidAimDirections();

		FVector TargetDirection = AimComponent.GetPlayerAimingRay().Direction;

		//AcceleratedAimDirection.AccelerateTo(TargetDirection, SidescrollerWeaponUserComponent.AimAccelerationDuration, DeltaTime);
		WeaponUserComponent.WeaponAnimData.AimDirection = TargetDirection;

		// Show all the widgets for the current aiming
		//TargetContainerComponent.ShowWidgetsForTargetables(UIslandRedBlueTargetableComponent, WeaponUserComponent.Default2DAimWidget);

		if(WeaponUserComponent.bUseOutlines)
			TargetContainerComponent.ShowOutlinesForTargetables(OutlineSettings);
	}

	void ConstrainAimToValidAimDirections()
	{
		AimComponent.ClearAimingRayOverride(this);

		// Get original aiming ray, then constrain it!
		FAimingRay Ray = AimComponent.GetPlayerAimingRay();
		Ray.Direction = GetConstrainedAimToValidAimDirections(Ray.Direction);

		AimComponent.ApplyAimingRayOverride(Ray, this, EInstigatePriority::High);
	}

	FVector GetConstrainedAimToValidAimDirections(FVector Direction)
	{
		float HighestDot = -1.0;
		FVector HighestDotDirection = Direction;
		for(FVector ValidDirection : ValidAimDirections)
		{
			float Dot = Direction.DotProduct(ValidDirection);
			if(Dot > HighestDot)
			{
				HighestDot = Dot;
				HighestDotDirection = ValidDirection;
			}
		}

		return HighestDotDirection;
	}

	void SetupValidAimDirections()
	{
		ValidAimDirections.Reset();
		FVector SplineForward = AimComponent.Get2DConstraintSplineForward();
		FVector Up = Player.MovementWorldUp;
		FVector Forward = SplineForward.VectorPlaneProject(Up).GetSafeNormal();

		// Cardinal directions
		ValidAimDirections.Add(Up);
		ValidAimDirections.Add(Forward);
		ValidAimDirections.Add(-Up);
		ValidAimDirections.Add(-Forward);

		// Diagonal directions
		ValidAimDirections.Add((Forward + Up).GetSafeNormal());
		ValidAimDirections.Add((Forward - Up).GetSafeNormal());
		ValidAimDirections.Add((-Forward - Up).GetSafeNormal());
		ValidAimDirections.Add((-Forward + Up).GetSafeNormal());
	}
}