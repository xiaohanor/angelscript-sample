class USummitTeenDragonRollingLiftJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90;

	UPlayerTeenDragonComponent DragonComp;
	USummitTeenDragonRollingLiftComponent LiftComp;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData Movement;

	ASummitRollingLift CurrentRollingLift;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LiftComp = USummitTeenDragonRollingLiftComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!DragonComp.bWantToJump)
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
		DragonComp.ConsumeJumpInput();

		CurrentRollingLift = LiftComp.CurrentRollingLift;

		Player.ActorVelocity += FVector::UpVector * CurrentRollingLift.JumpImpulse;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(DragonComp == nullptr)
			DragonComp = UPlayerTeenDragonComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				Movement.AddGravityAcceleration();
				Movement.AddOwnerVerticalVelocity();

				FVector CurrentVelocity = MoveComp.GetHorizontalVelocity();
				Movement.AddVelocity(CurrentVelocity);
				Movement.AddPendingImpulses();
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(n"RollMovement");
		}
	}
};