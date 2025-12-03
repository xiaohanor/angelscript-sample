class USkippingStonesAimCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	USkippingStonesPlayerComponent PlayerComp;
	UPlayerAimingComponent AimComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = USkippingStonesPlayerComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PlayerComp.State != ESkippingStonesState::Aim)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PlayerComp.State != ESkippingStonesState::Aim)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FAimingSettings AimingSettings;
		AimingSettings.bShowCrosshair = true;
		AimingSettings.bUseAutoAim = false;
		AimComp.StartAiming(PlayerComp, AimingSettings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.StopAiming(PlayerComp);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};