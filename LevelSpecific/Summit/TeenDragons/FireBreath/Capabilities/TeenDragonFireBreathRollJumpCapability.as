class UTeenDragonFireBreathRollJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonRoll);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonJump);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 17;

	UPlayerMovementComponent MoveComp;
	UTeenDragonRollMovementData Movement;

	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonFireBreathComponent FireBreathComp;
	UTeenDragonRollComponent RollComp;

	UTeenDragonFireBreathSettings Settings;

	float GraceTime = 0.35;
	float GraceTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		FireBreathComp = UTeenDragonFireBreathComponent::Get(Player);

		RollComp = UTeenDragonRollComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Owner);
		Movement = Cast<UTeenDragonRollMovementData>(MoveComp.SetupMovementData(UTeenDragonRollMovementData));
	
		Settings = UTeenDragonFireBreathSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!RollComp.IsRolling())
			return false;
		
		if (!WasActionStartedDuringTime(Settings.InputActionName, Settings.FireJumpInputGraceTime))
			return false;

		if(!MoveComp.IsOnAnyGround())
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
		Player.ConsumeButtonInputsRelatedTo(Settings.InputActionName);
		DragonComp.ConsumeJumpInput();

		float JumpImpulseSize = Settings.FireJumpImpulse;
		float UpwardsSpeed = MoveComp.Velocity.DotProduct(MoveComp.WorldUp);
		UpwardsSpeed = Math::Max(UpwardsSpeed, 0);
		if(UpwardsSpeed > JumpImpulseSize)
			JumpImpulseSize = 0;
		FVector JumpImpulse = MoveComp.WorldUp * JumpImpulseSize; 
		FVector VerticalVelocity = MoveComp.VerticalVelocity;
		VerticalVelocity += JumpImpulse;

		FVector CurrentHorizontalVelocity = MoveComp.HorizontalVelocity;
		Owner.SetActorHorizontalAndVerticalVelocity(CurrentHorizontalVelocity, VerticalVelocity);

		TEMPORAL_LOG(Player, "Teen Dragon Roll Jump")
			.DirectionalArrow("Jump Impulse", Player.ActorLocation, JumpImpulse, 10, 40, FLinearColor::Red)
		;

		// Audio events needs to be called on dragon
		ATeenDragon TeenDragon = Cast<ATeenDragon>(DragonComp.DragonMesh.GetOwner());
		DragonComp.GetTeenDragon();
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

		RollComp.RollingInstigators.AddUnique(this);

		Player.PlayForceFeedback(RollComp.RollJumpRumble, false, false, this);

		Niagara::SpawnOneShotNiagaraSystemAtLocation(Settings.FireJumpExplosion, Player.ActorLocation, Player.ActorRotation);
		Player.PlayCameraShake(Settings.CameraShake, this, 1.0);

		FireBreathComp.LastTimeFireJumped = Time::GameTimeSeconds;
		FireBreathComp.bHasBeenOnFireSinceLastFireJump = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.AnimationState.Clear(this);

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

		TEMPORAL_LOG(Player, "Teen Dragon Jump")
			.Value("Has Touched Ground Since Last Jump", DragonComp.bHasTouchedGroundSinceLastJump)
			.Value("Want to Jump", DragonComp.bWantToJump)
			.Value("Jump Input Consumed", DragonComp.bJumpInputConsumed)
		;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				Movement.AddOwnerVelocity();
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
};