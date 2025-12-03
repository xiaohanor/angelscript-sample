class UTundraPlayerTreeGuardianRangedInteractionAimingCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 95;
	default SeparateInactiveTick(EHazeTickGroup::Movement, 100);

	default CapabilityTags.Add(TundraRangedInteractionTags::RangedInteractionAiming);
	

	UTundraPlayerShapeshiftingComponent ShapeshiftingComp;
	UTundraPlayerTreeGuardianComponent TreeGuardianComp;
	UPlayerAimingComponent AimComp;
	UPlayerMovementComponent MoveComp;
	UTundraPlayerTreeGuardianSettings Settings;
	UWidgetPoolComponent WidgetPool;

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
		MoveComp = UPlayerMovementComponent::Get(Player);
		Settings = UTundraPlayerTreeGuardianSettings::GetSettings(Player);
		WidgetPool = UWidgetPoolComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(AimComp.HasAiming2DConstraint())
			return false;

		if(!Settings.bAllowRangedInteractionAimingWhileAirborne && !MoveComp.HasGroundContact() && TreeGuardianComp.CurrentRangedGrapplePoint == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(AimComp.HasAiming2DConstraint())
			return true;

		if(!Settings.bAllowRangedInteractionAimingWhileAirborne && !MoveComp.HasGroundContact() && TreeGuardianComp.CurrentRangedGrapplePoint == nullptr)
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
	void TickActive(float DeltaTime)
	{
		FAimingResult AimTarget = AimComp.GetAimingTarget(TreeGuardianComp);
		if (AimTarget.AutoAimTarget != nullptr)
		{
			auto Widget = Cast<UTundraPlayerTreeGuardianRangedInteractionCrosshairWidget>(WidgetPool.TakeSingleFrameWidget(TreeGuardianComp.RangedInteractionCrosshairClass, FInstigator(AimTarget.AutoAimTarget, n"TreeGuardianInteract")));
			Widget.AttachWidgetToComponent(AimTarget.AutoAimTarget);
			TreeGuardianComp.TargetedRangedInteractionCrosshair = Widget;
		}
		else
		{
			TreeGuardianComp.TargetedRangedInteractionCrosshair = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.StopAiming(TreeGuardianComp);
		TreeGuardianComp.GrappleAnimData.bIsInAiming = false;
		TreeGuardianComp.TargetedRangedInteractionCrosshair = nullptr;
	}
}