class UTundra_River_PlayerSnowballAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Movement;

	UTundra_River_PlayerSnowballComponent SnowballComp;
	UPlayerAimingComponent AimComp;
	UPlayerPerchComponent PerchComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SnowballComp = UTundra_River_PlayerSnowballComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
		PerchComp = UPlayerPerchComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(SnowballComp.Snowball == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(SnowballComp.Snowball == nullptr)
			return true;

		if(PerchComp.IsCurrentlyPerching())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SnowballComp.bIsThrowing = false;
		Player.BlockCapabilitiesExcluding(CapabilityTags::GameplayAction, PlayerMovementExclusionTags::ExcludePerch, this);

		FAimingSettings Settings;
		Settings.bShowCrosshair = true;
		Settings.OverrideCrosshairWidget = SnowballComp.CrosshairClass;
		Settings.bUseAutoAim = true;
		Settings.OverrideAutoAimTarget = UTundra_River_SnowballAutoAimTargetComponent;

		Player.EnableStrafe(this);

		AimComp.StartAiming(SnowballComp, Settings);

		Player.AddLocomotionFeature(SnowballComp.SnowballFeature, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DisableStrafe(this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		UPlayerAimingComponent::Get(Player).StopAiming(SnowballComp);

		Player.RemoveLocomotionFeature(SnowballComp.SnowballFeature, this);

		SnowballComp.Cancel();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.Mesh.CanRequestOverrideFeature())
			Player.Mesh.RequestOverrideFeature(n"Snowball", this);
	}
};