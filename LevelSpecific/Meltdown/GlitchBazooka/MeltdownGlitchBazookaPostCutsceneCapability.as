class UMeltdownGlitchBazookaPostCutsceneCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"GlitchShooting");

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 5;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UMeltdownGlitchShootingUserComponent UserComp;
	UMeltdownGlitchShootingSettings Settings;
	UPlayerAimingComponent AimingComp;
	UPlayerMovementComponent MoveComp;

	bool bHasDonePostCutscene = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UMeltdownGlitchShootingUserComponent::Get(Player);
		Settings = UMeltdownGlitchShootingSettings::GetSettings(Player);
		AimingComp = UPlayerAimingComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.bGlitchShootingActive)
			return false;
		if (bHasDonePostCutscene)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.MovementInput.Size() > 0.001)
			return true;
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (UserComp.bIsShooting)
			return true;
		if (!UserComp.bGlitchShootingActive)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UserComp.WeaponVisibility.Apply(true, this);
		UserComp.bCutsceneAiming = true;
		bHasDonePostCutscene = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UserComp.bCutsceneAiming = false;
		UserComp.WeaponVisibility.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.Mesh.CanRequestOverrideFeature())
			Player.Mesh.RequestOverrideFeature( n"GlitchWeaponStrafe", this);
	}
};