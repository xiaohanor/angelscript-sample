class UTeenDragonRollJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonRoll);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonJump);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 19;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UTeenDragonRollMovementData Movement;

	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonRollComponent RollComp;

	UTeenDragonRollSettings RollSettings;
	
	float GraceTime = 0.35;
	float GraceTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Owner);
		Movement = Cast<UTeenDragonRollMovementData>(MoveComp.SetupMovementData(UTeenDragonRollMovementData));

		RollSettings = UTeenDragonRollSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		
		if (!RollComp.IsRolling())
			return false;
		
		if (!DragonComp.bWantToJump)
			return false;

		if(!DragonComp.bHasTouchedGroundSinceLastJump)
			return false;

		if (GraceTimer < GraceTime)
			return true;

		if (MoveComp.IsOnWalkableGround())
			return true;

		return false;
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

		// Audio events needs to be called on dragon
		ATeenDragon TeenDragon = Cast<ATeenDragon>(DragonComp.DragonMesh.GetOwner());
		UTeenDragonRollEventHandler::Trigger_OnJump(TeenDragon);

		FTeenDragonRollOnJumpedParams OnJumpedParams;
		if(MoveComp.HasGroundContact())
		{
			OnJumpedParams.GroundLocation = MoveComp.GroundContact.ImpactPoint;
			OnJumpedParams.GroundNormal = MoveComp.GroundContact.ImpactNormal;
		}
		else
		{
			OnJumpedParams.GroundLocation = Player.ActorLocation;
			OnJumpedParams.GroundNormal = FVector::UpVector;
		}
		UTeenDragonRollVFX::Trigger_OnJumped(Player, OnJumpedParams);

		DragonComp.AnimationState.Apply(ETeenDragonAnimationState::TailRollJump, this);
		DragonComp.bIsRollJumping = true;
		RollComp.RollingInstigators.AddUnique(this);

		Player.PlayForceFeedback(RollComp.RollJumpRumble, false, false, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.AnimationState.Clear(this);
		DragonComp.bIsRollJumping = false;

		DragonComp.bIsInAirFromJumping = true;
		RollComp.RollingInstigators.RemoveSingleSwap(this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (MoveComp.IsInAir())
			GraceTimer += DeltaTime;
		else
			GraceTimer = 0.0;

		if(MoveComp.IsOnWalkableGround())
			DragonComp.bHasTouchedGroundSinceLastJump = true;

		if(MoveComp.IsOnAnyGround())
			DragonComp.bIsInAirFromJumping = false;

		TEMPORAL_LOG(Player, "Teen Dragon Jump")
			.Value("Has Touched Ground Since Last Jump", DragonComp.bHasTouchedGroundSinceLastJump)
			.Value("Want to Jump", DragonComp.bWantToJump)
			.Value("Jump Input Consumed", DragonComp.bJumpInputConsumed)
			.Value("Is In Air From Jumping", DragonComp.bIsInAirFromJumping)
		;
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				float JumpImpulseSize = RollSettings.RollJumpImpulse;
				float UpwardsSpeed = MoveComp.Velocity.DotProduct(MoveComp.WorldUp);
				UpwardsSpeed = Math::Max(UpwardsSpeed, 0);
				if(UpwardsSpeed > JumpImpulseSize)
					JumpImpulseSize = 0;
				FVector JumpImpulse = MoveComp.WorldUp * (JumpImpulseSize + UpwardsSpeed); 
				FVector VerticalVelocity = JumpImpulse;

				FVector CurrentHorizontalVelocity = MoveComp.HorizontalVelocity;

				Movement.AddHorizontalVelocity(CurrentHorizontalVelocity);
				Movement.AddVerticalVelocity(VerticalVelocity);

				TEMPORAL_LOG(Player, "Teen Dragon Roll Jump").DirectionalArrow("Jump Impulse", Player.ActorLocation, JumpImpulse, 10, 40, FLinearColor::Red);

				Movement.AddGravityAcceleration();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::RollMovement);
		}
	}
}