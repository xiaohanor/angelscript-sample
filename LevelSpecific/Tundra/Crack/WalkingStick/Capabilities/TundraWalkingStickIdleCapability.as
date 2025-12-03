class UTundraWalkingStickIdleCapability : UTundraWalkingStickBaseCapability
{
	default TickGroup = EHazeTickGroup::Input;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(WalkingStick.CurrentState != ETundraWalkingStickState::None)
			return false;

		if(!WalkingStick.bGameplaySpider)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(WalkingStick.CurrentState != ETundraWalkingStickState::None)
			return true;

		if(!WalkingStick.bGameplaySpider)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(WalkingStick.IsChargingScream() && Time::GetGameTimeSince(WalkingStick.TimeOfStartChargingScream.Value) > WalkingStick.ScreamChargeUpDuration)
		{
			WalkingStick.ClearScreamTutorial();
			WalkingStick.ShowReleaseTutorial();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WalkingStick.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), WalkingStick.IdleAnimation, true,
			EHazeBlendType::BlendType_Inertialization, 0.0, 0.2, 0.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		WalkingStick.StopSlotAnimationByAsset(WalkingStick.IdleAnimation, 0.4);
	}
}