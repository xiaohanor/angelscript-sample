class USummitTeenDragonRollingLiftJumpInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::Input);

	default CapabilityTags.Add(n"GroundMovement");
	default CapabilityTags.Add(n"BaseMovement");
	default CapabilityTags.Add(n"Jump");
	default CapabilityTags.Add(n"JumpInput");

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerTeenDragonComponent DragonComp;
	UHazeMovementComponent MoveComp;

	float GraceTime = 0.35;
	float GraceTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStartedDuringTime(ActionNames::MovementJump, 0.2))
			return false;
		
		if(DeactiveDuration < 0.2)
			return false;

		if(!DragonComp.bHasTouchedGroundSinceLastJump)
			return false;

		if (MoveComp.IsInAir() 
		&& GraceTimer > GraceTime)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.IsInAir() 
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
		DragonComp.AnimationState.Clear(this);
		DragonComp.bJumpInputConsumed = false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(DragonComp == nullptr)
			DragonComp = UPlayerTeenDragonComponent::Get(Player);
		if(MoveComp == nullptr)
			MoveComp = UHazeMovementComponent::Get(Player);

		if (MoveComp.IsInAir())
			GraceTimer += DeltaTime;
		else
			GraceTimer = 0.0;

		if(MoveComp.HasGroundContact())
			DragonComp.bHasTouchedGroundSinceLastJump = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!DragonComp.bWantToJump)
		{
			DragonComp.bWantToJump = true;
		}
			
	}
}