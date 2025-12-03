class USkylineLaunchPadPostLaunchCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	USkylineLaunchPadUserComponent UserComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USkylineLaunchPadUserComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.bIsLaunched)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.VerticalSpeed < 0.0)
			return true;

		if(MoveComp.HasGroundContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UserComp.bIsLaunched = false;

		UPlayerAirMotionSettings::SetAirControlMultiplier(Player, 0.0, this);
		UPlayerAirMotionSettings::SetDragOfExtraHorizontalVelocity(Player, 0.0, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UPlayerAirMotionSettings::ClearAirControlMultiplier(Player, this);
		UPlayerAirMotionSettings::ClearDragOfExtraHorizontalVelocity(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PrintToScreen("PostLaunch", 0.0, FLinearColor::Yellow);
	}
};