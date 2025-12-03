

class UTeenDragonTailGeckoClimbJumpInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonJump);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 90;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonTailGeckoClimbComponent GeckoClimbComp;

	UHazeMovementComponent MoveComp;

	float GraceTime = 0.35;
	float GraceTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		GeckoClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!DragonComp.IsClimbing())
			return false;

		if (!WasActionStartedDuringTime(ActionNames::MovementJump, 0.2)
		&& !WasActionStartedDuringTime(ActionNames::MovementDash, 0.2))
			return false;
		
		if(DeactiveDuration < 0.2)
			return false;

		if ((GeckoClimbComp.bIsGeckoDashing || GeckoClimbComp.bGeckoDashIsCoolingDown) 
		&& GraceTimer > GraceTime)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!DragonComp.IsClimbing())
			return true;

		if ((GeckoClimbComp.bIsGeckoDashing || GeckoClimbComp.bGeckoDashIsCoolingDown) 
		&& GraceTimer > GraceTime)
			return true;

		if(DragonComp.bJumpInputConsumed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.bWantToJump = false;
		DragonComp.bJumpInputConsumed = false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (GeckoClimbComp.bIsGeckoDashing || GeckoClimbComp.bGeckoDashIsCoolingDown)
			GraceTimer += DeltaTime;
		else
			GraceTimer = 0.0;
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!DragonComp.bWantToJump)
			DragonComp.bWantToJump = true;
	}
}