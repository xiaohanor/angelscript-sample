class UGravityBikeWhipSideScrollerCrosshairCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);
	default CapabilityTags.Add(GravityBikeWhip::Tags::GravityBikeWhip);
	default CapabilityTags.Add(GravityBikeWhip::Tags::GravityBikeWhipAim);

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 110;

	UGravityBikeWhipComponent WhipComp;
	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent PlayerTargetables;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WhipComp = UGravityBikeWhipComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
		PlayerTargetables = UPlayerTargetablesComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
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
		AimComp.ApplyAiming2DCameraPlaneConstraint(this);
		PlayerTargetables.TargetingMode.Apply(EPlayerTargetingMode::SideScroller, this);

		UPlayerAimingSettings::SetGamepadAllowBothSticks(Player, true, this);

		FAimingSettings AimSettings;
		AimSettings.bShowCrosshair = true;
		AimSettings.bCrosshairFollowsTarget = false;
		AimSettings.bUseAutoAim = false;
		AimSettings.Crosshair2DSettings.DirectionOffset = GravityBikeWhip::SideScrollerOffset;
		AimSettings.Crosshair2DSettings.CrosshairOffset2D = GravityBikeWhip::SideScrollerArrowDistance;
		AimSettings.Crosshair2DSettings.DirectionalArrowSize = 0;
		AimComp.StartAiming(this, AimSettings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.ClearAiming2DConstraint(this);
		PlayerTargetables.TargetingMode.Clear(this);

		UPlayerAimingSettings::ClearGamepadAllowBothSticks(Player, this);

		AimComp.StopAiming(this);

		MoveComp.ClearGravityDirectionOverride(this);
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		// 2D aiming requires WorldUp to be correct, so we force set it here
		MoveComp.OverrideGravityDirection(FMovementGravityDirection::TowardsDirection(-Player.ActorUpVector), this);
	}
}