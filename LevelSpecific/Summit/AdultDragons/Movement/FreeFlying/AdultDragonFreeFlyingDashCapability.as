class UAdultDragonFreeFlyingDashCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragonAirDash);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90;

	default DebugCategory = SummitDebugCapabilityTags::AdultDragon;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerAdultDragonComponent DragonComp;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData Movement;

	FHazeAcceleratedQuat AccRotation;

	FRotator DashRotationOffset;
	FRotator DashRotation;

	float StartForwardSpeed = 0.0;

	bool bFirstFrameActive = false;

	const float DashDuration = 1;
	const float DashCooldown = 1;

	UAdultDragonStrafeSettings StrafeSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerAdultDragonComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();

		StrafeSettings = UAdultDragonStrafeSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!WasActionStarted(ActionNames::MovementDash))
			return false;

		if (DeactiveDuration < DashCooldown)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (ActiveDuration >= DashDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(AdultDragonCapabilityTags::AdultDragonSmashMode, this);

		DragonComp.AnimationState.Apply(EAdultDragonAnimationState::Dash, this, EInstigatePriority::High);
		DragonComp.AnimParams.bDashInitialized = true;
		
		bFirstFrameActive = true;

		AccRotation.SnapTo(Player.ActorRotation.Quaternion());

		StartForwardSpeed = Player.ActorVelocity.DotProduct(Player.ActorForwardVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(AdultDragonCapabilityTags::AdultDragonSmashMode, this);

		DragonComp.AnimationState.Clear(this);
		// StrafeComp.AnimationState.Clear(this);
		Player.ClearCameraSettingsByInstigator(this, 1.5);
		DragonComp.BonusSpeed.Remove(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bFirstFrameActive && DragonComp.AnimParams.bDashInitialized)
			DragonComp.AnimParams.bDashInitialized = false;

		float DashAlpha = ActiveDuration / StrafeSettings.DashDuration;

		float DashSpeed = StrafeSettings.DashSpeedCurve.GetFloatValue(DashAlpha) * 20000;
		DragonComp.BonusSpeed.FindOrAdd(this) = DashSpeed;
		bFirstFrameActive = false;
	}
}