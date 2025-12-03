class UTundraPlayerTreeGuardianRangedInteractionAiming2DCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 95;
	default SeparateInactiveTick(EHazeTickGroup::Movement, 100);

	default CapabilityTags.Add(TundraRangedInteractionTags::RangedInteractionAiming);

	UTundraPlayerShapeshiftingComponent ShapeshiftingComp;
	UTundraPlayerTreeGuardianComponent TreeGuardianComp;
	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent PlayerTargetablesComp;

	FAimingSettings AimSettings;
	default AimSettings.bShowCrosshair = false;
	default AimSettings.bCrosshairFollowsTarget = true;
	default AimSettings.bUseAutoAim = true;
	default AimSettings.OverrideAutoAimTarget = UTundraTreeGuardianRangedInteractionTargetableComponent;
	default AimSettings.bApplyAimingSensitivity = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!AimComp.HasAiming2DConstraint())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!AimComp.HasAiming2DConstraint())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AimComp.StartAiming(TreeGuardianComp, AimSettings);
		TreeGuardianComp.GrappleAnimData.bIsInAiming = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.StopAiming(TreeGuardianComp);
		TreeGuardianComp.GrappleAnimData.bIsInAiming = false;
		AimComp.ClearAimingRayOverride(TreeGuardianComp);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!AimComp.HasAiming2DConstraint())
			return;

		FVector Forward = AimComp.Get2DConstraintSplineForward();

		FAimingRay Ray;
		Ray.AimingMode = EAimingMode::Directional2DAim;
		Ray.Origin = Player.ActorCenterLocation;
		Ray.Direction = Forward * Math::Sign(Forward.DotProduct(Player.ActorForwardVector * (TreeGuardianComp.CurrentRangedGrapplePoint != nullptr ? -1.0 : 1.0)));
		AimComp.ApplyAimingRayOverride(Ray, TreeGuardianComp, EInstigatePriority::High);
		
		PlayerTargetablesComp.ShowWidgetsForTargetables(UTundraTreeGuardianRangedInteractionTargetableComponent, TreeGuardianComp.RangedInteractionTargetableWidget2DClass);
	}
}