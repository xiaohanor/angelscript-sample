class UTundraWalkingStickCrashInWallCapability : UTundraWalkingStickBaseCapability
{
	default TickGroup = EHazeTickGroup::Movement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(WalkingStick.CurrentState != ETundraWalkingStickState::CrashInWall)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(WalkingStick.CurrentState != ETundraWalkingStickState::CrashInWall)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WalkingStick.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), WalkingStick.CrashInWallAnimation, false,
			EHazeBlendType::BlendType_Inertialization, 0.4, 0.0, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		WalkingStick.StopSlotAnimationByAsset(WalkingStick.CrashInWallAnimation);
	}
}