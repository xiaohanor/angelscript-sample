class UBattlefieldHoverboardGrindJumpInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"HoverboardGrindJumpInput");

	default DebugCategory = n"Hoverboard";

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	UBattlefieldHoverboardJumpComponent JumpComp;
	UBattlefieldHoverboardGrindingComponent GrindComp;
	UPlayerMovementComponent MoveComp;

	UBattlefieldHoverboardJumpSettings JumpSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JumpComp = UBattlefieldHoverboardJumpComponent::Get(Player);
		GrindComp = UBattlefieldHoverboardGrindingComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);

		JumpSettings = UBattlefieldHoverboardJumpSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!GrindComp.IsGrinding())
			return false;

		if(!WasActionStartedDuringTime(ActionNames::MovementJump, JumpSettings.JumpBufferTime))
			return false;

		if(DeactiveDuration < JumpSettings.JumpGraceTime)
			return false;

		if(!GrindComp.bIsOnGrind)		
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);

		JumpComp.bWantToJump = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		JumpComp.bWantToJump = false;
		JumpComp.bJumpInputConsumed = false;
	}
};