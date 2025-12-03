asset TundraWaterslideLaunchPlayerAirSettings of UPlayerAirMotionSettings
{
	DragOfExtraHorizontalVelocity = 0.0;
	AirControlMultiplier = 0.0;
} 

class UTundra_River_WaterslideLaunch_PlayerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::InfluenceMovement;

	UTundra_River_WaterslideLaunch_PlayerComponent LaunchComp;

	UPlayerMovementComponent MoveComp;

	bool bTimerActive = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LaunchComp = UTundra_River_WaterslideLaunch_PlayerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);

		if(LaunchComp == nullptr)
			PrintToScreenScaled("No Launch Comp Found!", 10, FLinearColor::Red);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(LaunchComp.BlockTimer > 0)
			return true;


		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasGroundContact() || Player.IsPlayerDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(n"AirJump", this);
		Player.BlockCapabilities(n"Slide", this);
		Player.BlockCapabilities(n"MovementInput", this);
		Player.ApplySettings(TundraWaterslideLaunchPlayerAirSettings, this);
		LaunchComp.bIsBlockActive = true;
		bTimerActive = true;
		Player.PlayForceFeedback(LaunchComp.WaterslideLaunchFF, false, false, this);
		Player.PlayCameraShake(LaunchComp.WaterslideLaunchCameraShake, this);

		if(LaunchComp.bDebug)
			PrintToScreen("Blocked Capabilities", 3);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(n"AirJump", this);
		Player.UnblockCapabilities(n"Slide", this);
		Player.UnblockCapabilities(n"MovementInput", this);
		Player.ClearSettingsByInstigator(this);
		LaunchComp.bIsBlockActive = false;

		if(LaunchComp.bDebug)
			PrintToScreen("Unblocked Capabilities", 3);

		LaunchComp.BlockTimer = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(LaunchComp.BlockTimer <= 0)
			bTimerActive = false;
		else
			LaunchComp.BlockTimer -= DeltaTime;

		if(LaunchComp.bDebug)
			PrintToScreen("Current Timer: " + LaunchComp.BlockTimer);
	}
};