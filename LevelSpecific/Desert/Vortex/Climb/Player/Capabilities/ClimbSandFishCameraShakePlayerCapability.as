class UClimbSandFishCameraShakePlayerCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 60;

	UClimbSandFishPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UClimbSandFishPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Desert::GetDesertLevelState() != EDesertLevelState::Climb)
			return false;

		if(!PlayerComp.IsStandingOnFish())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Desert::GetDesertLevelState() != EDesertLevelState::Climb)
			return true;

		if(!PlayerComp.IsStandingOnFish())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.PlayCameraShake(PlayerComp.CameraShake, this, 0.75);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.StopCameraShakeByInstigator(this);
	}
};