class UGravityWhipAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(GravityWhipTags::GravityWhip);
	default CapabilityTags.Add(GravityWhipTags::GravityWhipAim);
	default CapabilityTags.Add(GravityWhipTags::GravityWhipGameplay);

	default DebugCategory = GravityWhipTags::GravityWhip;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 90;

	UGravityWhipUserComponent UserComp;
	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent PlayerTargetablesComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UGravityWhipUserComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (UserComp.IsGrabbingAny())
		{
			if (UserComp.GetPrimaryGrabMode() == EGravityWhipGrabMode::Sling)
				return false;
		}

		if (AimComp.IsAiming(UserComp))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (UserComp.IsGrabbingAny())
		{
			if (UserComp.GetPrimaryGrabMode() == EGravityWhipGrabMode::Sling)
				return true;
		}

		return false;	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FAimingSettings AimSettings;
		AimSettings.bUseAutoAim = false;
		AimSettings.bShowCrosshair = GravityWhip::Common::bShowCrosshair;
		AimSettings.bApplyAimingSensitivity = GravityWhip::Common::bApplyAimingSensitivity;
		AimSettings.OverrideAutoAimTarget = UGravityWhipTargetComponent;
		AimSettings.OverrideCrosshairWidget = UserComp.CrosshairWidget;
		AimComp.StartAiming(UserComp, AimSettings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.StopAiming(UserComp);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}