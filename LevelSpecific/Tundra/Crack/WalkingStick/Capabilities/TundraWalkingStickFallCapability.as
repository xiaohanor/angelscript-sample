class UTundraWalkingStickFallCapability : UTundraWalkingStickBaseCapability
{
	default TickGroup = EHazeTickGroup::Movement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(WalkingStick.CurrentState != ETundraWalkingStickState::Falling)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(WalkingStick.CurrentState != ETundraWalkingStickState::Falling)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WalkingStick.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), WalkingStick.FallingAnimation, false,
			EHazeBlendType::BlendType_Inertialization, 0.4, 0.0, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		WalkingStick.StopSlotAnimationByAsset(WalkingStick.FallingAnimation);
	}
}