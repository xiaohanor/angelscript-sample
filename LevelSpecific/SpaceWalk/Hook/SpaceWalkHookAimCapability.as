class USpaceWalkHookAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	USpaceWalkPlayerComponent SpaceComp;
	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent PlayerTargetablesComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SpaceComp = USpaceWalkPlayerComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
		PlayerTargetablesComponent = UPlayerTargetablesComponent::Get(Player);
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
		FAimingSettings AimSettings;
		AimSettings.bShowCrosshair = false;
		AimSettings.bApplyAimingSensitivity = false;

		AimComp.StartAiming(SpaceComp, AimSettings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.StopAiming(SpaceComp);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};