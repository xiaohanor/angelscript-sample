class UMagnetDroneJumpInputCapability : UHazePlayerCapability
{
	// Input is always just local
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	UMagnetDroneJumpComponent JumpComp;
	UMagnetDroneAttractionComponent AttractionComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JumpComp = UMagnetDroneJumpComponent::Get(Player);
		AttractionComp = UMagnetDroneAttractionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		if(!AttractionComp.IsAttractionInputAllowed())
			return false;

		if(!WasActionStartedDuringTime(ActionNames::MovementJump, AttractionComp.Settings.InputBuffer))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!IsActioning(ActionNames::MovementJump))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		JumpComp.bIsInputtingJump = true;
		JumpComp.StartJumpInputFrame = Time::FrameNumber;
		JumpComp.StartJumpInputTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		JumpComp.bIsInputtingJump = false;

		if(IsBlocked())
			JumpComp.ConsumeJumpInput();
	}
};