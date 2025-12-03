

class UTeenDragonJumpInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonJump);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerTeenDragonComponent DragonComp;
	UPlayerTailTeenDragonComponent TailComp;
	UTeenDragonRollComponent RollComp;

	UHazeMovementComponent MoveComp;
	UTeenDragonTailGeckoClimbComponent GeckoClimbComp;

	UTeenDragonJumpSettings JumpSettings;

	const float GraceTime = 0.25;
	float GraceTimer = 0.0;

	const float JumpQueueTime = 0.2;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTeenDragonComponent::Get(Player);
		TailComp = UPlayerTailTeenDragonComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);
		GeckoClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Player);

		JumpSettings = UTeenDragonJumpSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(DragonComp.IsTailDragon())
		{
			if(RollComp.IsRolling() || TailComp.IsClimbing())
				return false;
		}

		if (!WasActionStartedDuringTime(ActionNames::MovementJump, JumpQueueTime))
			return false;
		
		if(DeactiveDuration < JumpQueueTime)
			return false;

		if(!DragonComp.bHasTouchedGroundSinceLastJump)
			return false;

		if (!MoveComp.IsOnWalkableGround() 
		&& GraceTimer > GraceTime)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(DragonComp.IsTailDragon())
		{
			if(RollComp.IsRolling() || TailComp.IsClimbing())
				return true;
		}

		if (!MoveComp.IsOnWalkableGround() 
		&& GraceTimer > GraceTime)
			return true;

		if(DragonComp.bJumpInputConsumed)
			return true;

		if(ActiveDuration > JumpQueueTime)
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
		if (MoveComp.IsInAir()
		|| DragonComp.bIsLedgeGrabbing 
		|| DragonComp.bIsLedgeDowning)
			GraceTimer += DeltaTime;
		else
			GraceTimer = 0.0;

		if(MoveComp.IsOnWalkableGround())
			DragonComp.bHasTouchedGroundSinceLastJump = true;

		TEMPORAL_LOG(Player, "Teen Dragon Jump")
			.Value("Has Touched Ground Since Last Jump", DragonComp.bHasTouchedGroundSinceLastJump)
			.Value("Want to Jump", DragonComp.bWantToJump)
			.Value("Jump Input Consumed", DragonComp.bJumpInputConsumed)
		;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!DragonComp.bIsLedgeGrabbing 
		&& !DragonComp.bIsLedgeDowning)
			DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::Jump);

		if (!DragonComp.bWantToJump || MoveComp.IsInAir())
		{
			if(!DragonComp.bHasTouchedGroundSinceLastJump)
				return;
			
			if(DragonComp.bJumpInputConsumed)
				return;

			if(MoveComp.IsOnWalkableGround()
			&& ActiveDuration < JumpSettings.AnticipationDelay)
				return;
			
			DragonComp.bWantToJump = true;
		}
	}
}