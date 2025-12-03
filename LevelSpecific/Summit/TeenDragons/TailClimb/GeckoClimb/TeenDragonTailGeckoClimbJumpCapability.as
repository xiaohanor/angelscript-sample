class UTeenDragonTailGeckoClimbJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonTailClimb);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 40;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;

	UPlayerTailTeenDragonComponent TailDragonComp;
	UTeenDragonTailGeckoClimbComponent GeckoClimbComp;

	UTeenDragonTailClimbableComponent CurrentClimbComp;

	UTeenDragonTailGeckoClimbSettings ClimbSettings;

	float JumpStartVerticalSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		TailDragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		GeckoClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);

		ClimbSettings = UTeenDragonTailGeckoClimbSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!TailDragonComp.IsClimbing())
			return false;

		if(!TailDragonComp.bWantToJump)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (MoveComp.HasGroundContact())
			return true;
		
		if(GeckoClimbComp.bMissedGeckoJumping) 
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(BlockedWhileIn::Jump, this);

		TailDragonComp.ConsumeJumpInput();
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);

		TailDragonComp.AnimationState.Apply(ETeenDragonAnimationState::Jump, this);

		FVector Target = Player.ActorLocation + Player.ActorForwardVector * ClimbSettings.JumpLength;

		FVector NewVelocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(Player.ActorLocation, Target, 
			MoveComp.GravityForce, ClimbSettings.JumpHorizontalSpeed, MoveComp.WorldUp);

		Owner.SetActorVelocity(NewVelocity);

		JumpStartVerticalSpeed = Player.ActorVerticalVelocity.DotProduct(MoveComp.WorldUp);

		// Add jump impulse
		// FVector VerticalVelocity = MoveComp.WorldUp;
		// VerticalVelocity *= ClimbSettings.JumpHeightImpulse;

		// FVector CurrentHorizontalVelocity = MoveComp.HorizontalVelocity;

		// Owner.SetActorHorizontalAndVerticalVelocity(CurrentHorizontalVelocity, VerticalVelocity);

		// if(!TailDragonComp.bTopDownMode)
		// 	Player.PlayCameraShake(GeckoClimbComp.JumpOffShake, this);
		
		GeckoClimbComp.bIsGeckoJumping = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(BlockedWhileIn::Jump, this);		
		TailDragonComp.AnimationState.Clear(this);


		GeckoClimbComp.bIsGeckoJumping = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				Movement.AddHorizontalVelocity(Player.ActorForwardVector * ClimbSettings.JumpHorizontalSpeed);
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.InterpRotationToTargetFacingRotation(ClimbSettings.JumpTurnSpeed * MoveComp.MovementInput.Size());
			
				if (MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp) < -JumpStartVerticalSpeed * 1.1)
				{
					GeckoClimbComp.bMissedGeckoJumping = true;
				}
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMove(Movement);
			TailDragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::Jump);
		}
	}
};