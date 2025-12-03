class UGameShowArenaBombTossGrappleAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"BombTossGrapple");

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 80;

	UGameShowArenaBombTossPlayerComponent BombTossPlayerComponent;
	UPlayerAimingComponent PlayerAimComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BombTossPlayerComponent = UGameShowArenaBombTossPlayerComponent::Get(Player);
		PlayerAimComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (BombTossPlayerComponent.CurrentBomb != nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (BombTossPlayerComponent.CurrentBomb != nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FAimingSettings AimSettings;
		AimSettings.bShowCrosshair = true;
		AimSettings.OverrideAutoAimTarget = UGameShowArenaBombTossGrapplePointComponent;
		AimSettings.bCrosshairFollowsTarget = true;
		AimSettings.bApplyAimingSensitivity = false;
		AimSettings.bUseAutoAim = true;

		PlayerAimComp.StartAiming(n"BombTossGrapple", AimSettings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerAimComp.StopAiming(n"BombTossGrapple");
	}
}