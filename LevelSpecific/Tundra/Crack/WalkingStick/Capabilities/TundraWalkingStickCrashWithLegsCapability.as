class UTundraWalkingStickCrashWithLegsCapability : UTundraWalkingStickBaseCapability
{
	default TickGroup = EHazeTickGroup::Input;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UAnimSequence CurrentAnimation;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(WalkingStick.CurrentState != ETundraWalkingStickState::CrashWithLegs)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(WalkingStick.CurrentState != ETundraWalkingStickState::CrashWithLegs)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CurrentAnimation = WalkingStick.CurrentCrashWithLegsType == ETundraWalkingStickCrashWithLegsType::Left ? WalkingStick.CrashWithLegsFallRightAnimation : WalkingStick.CrashWithLegsFallLeftAnimation;
		WalkingStick.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), CurrentAnimation, false,
			EHazeBlendType::BlendType_Inertialization, 0.4, 0.0, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		WalkingStick.StopSlotAnimationByAsset(CurrentAnimation);
	}
}