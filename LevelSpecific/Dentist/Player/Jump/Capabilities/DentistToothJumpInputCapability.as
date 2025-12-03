class UDentistToothJumpInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(Dentist::Tags::CancelOnRagdoll);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	UDentistToothJumpComponent JumpComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JumpComp = UDentistToothJumpComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;
		
		if(!WasActionStarted(ActionNames::MovementJump))
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

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		
	}
};