class UBombTossGrappleAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"BombTossGrapple");

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 80;

	UBombTossPlayerComponent BombTossPlayerComponent;
	UPlayerAimingComponent PlayerAimComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BombTossPlayerComponent = UBombTossPlayerComponent::Get(Player);
		PlayerAimComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(BombTossPlayerComponent.CurrentBombToss != nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(BombTossPlayerComponent.CurrentBombToss != nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FAimingSettings AimSettings;
		AimSettings.bShowCrosshair = true;
		AimSettings.OverrideAutoAimTarget = UBombTossGrapplePointComponent;
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