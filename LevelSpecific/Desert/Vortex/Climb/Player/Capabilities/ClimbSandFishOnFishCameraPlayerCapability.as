class UClimbSandFishOnFishCameraPlayerCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 90;

	//default CapabilityTags.Add(ArenaSandFish::PlayerTags::ArenaSandFishPlayerCamera);
	//default CapabilityTags.Add(ArenaSandFish::PlayerTags::ArenaSandFishPlayerOnFishCamera);

	UClimbSandFishPlayerComponent PlayerComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UClimbSandFishPlayerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Desert::GetDesertLevelState() != EDesertLevelState::Climb)
			return false;

		if(ClimbSandFish::IsPlayerInteracting(Player))
			return false;

		if(!PlayerComp.IsStandingOnFish())
			return false;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Desert::GetDesertLevelState() != EDesertLevelState::Climb)
			return true;

		if(ClimbSandFish::IsPlayerInteracting(Player))
			return true;

		if(!PlayerComp.IsStandingOnFish())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplyCameraSettings(PlayerComp.CameraSettings, 2, this, EHazeCameraPriority::High, -1);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this);
	}
};