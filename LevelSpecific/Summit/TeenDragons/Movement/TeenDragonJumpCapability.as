class UTeenDragonJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonJump);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UTeenDragonMovementData Movement;

	UPlayerTeenDragonComponent DragonComp;
	
	UTeenDragonJumpSettings JumpSettings;
	UTeenDragonMovementSettings MovementSettings;

	float GraceTime = 0.35;
	float GraceTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTeenDragonComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupMovementData(UTeenDragonMovementData);

		JumpSettings = UTeenDragonJumpSettings::GetSettings(Player);
		MovementSettings = UTeenDragonMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
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
		Owner.BlockCapabilities(BlockedWhileIn::Jump, this);

		DragonComp.ConsumeJumpInput();
		DragonComp.bIsInAirFromJumping = true;
		DragonComp.AnimationState.Apply(ETeenDragonAnimationState::Jump, this);

		// Add jump impulse
		float JumpImpulseSize = JumpSettings.JumpImpulse;
		float UpwardsSpeed = MoveComp.Velocity.DotProduct(MoveComp.WorldUp);
		UpwardsSpeed = Math::Max(UpwardsSpeed, 0);
		if(UpwardsSpeed > JumpImpulseSize)
			JumpImpulseSize -= UpwardsSpeed;
		float ImpulseSpeed = MoveComp.PendingImpulse.DotProduct(MoveComp.WorldUp);
		ImpulseSpeed = Math::Max(ImpulseSpeed, 0);
		if(ImpulseSpeed > JumpImpulseSize)
			JumpImpulseSize -= ImpulseSpeed;

		JumpImpulseSize = Math::Max(JumpImpulseSize, 0);
		FVector VerticalVelocity = MoveComp.VerticalVelocity;
		if(VerticalVelocity.Z < 0)
			VerticalVelocity.Z = 0;
		FVector JumpImpulse = MoveComp.WorldUp * JumpImpulseSize;
		VerticalVelocity += JumpImpulse;

		TEMPORAL_LOG(Player, "Teen Dragon Jump")
			.DirectionalArrow("Jump Impulse", Player.ActorLocation, JumpImpulse, 5, 40, FLinearColor::Blue)
			.Value("Upwards Speed Pre jump", UpwardsSpeed)
		;

		FVector CurrentHorizontalVelocity = MoveComp.HorizontalVelocity;
		CurrentHorizontalVelocity = CurrentHorizontalVelocity.GetClampedToMaxSize(MovementSettings.MaximumSpeed);

		GetGroundAlignedAdjustedVelocity(CurrentHorizontalVelocity, VerticalVelocity);
		Owner.SetActorHorizontalAndVerticalVelocity(CurrentHorizontalVelocity, VerticalVelocity);
	
		Player.PlayForceFeedback(DragonComp.JumpRumble, false, true, this, 0.1);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(BlockedWhileIn::Jump, this);		
		DragonComp.AnimationState.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!MoveComp.IsInAir())
			DragonComp.bIsInAirFromJumping = false;

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
				Movement.AddPendingImpulses();

				Movement.InterpRotationToTargetFacingRotation(MovementSettings.AirFacingDirectionInterpSpeed * MoveComp.MovementInput.Size(), false);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::Jump);
		}
	}

	void GetGroundAlignedAdjustedVelocity(FVector& HorizontalVelocity, FVector& VerticalVelocity) const
	{
		if(!MoveComp.IsOnWalkableGround())
			return;

		FVector GroundNormal = MoveComp.GetCurrentGroundNormal();
		float SlopeDot = GroundNormal.DotProduct(Owner.ActorForwardVector);
		float SlopeAngle = Math::RadiansToDegrees(SlopeDot);
		float Alpha = Math::Abs(SlopeAngle) / MoveComp.WalkableSlopeAngle;

		// Downhill
		if (SlopeDot > KINDA_SMALL_NUMBER)
		{
			// align the horizontal velocity with the world up, 
			//making us leave the ground and not follow the slope down
			FVector HorizontalAlignedVelocity = HorizontalVelocity.VectorPlaneProject(MoveComp.WorldUp).GetSafeNormal() * HorizontalVelocity.Size();	
			Alpha = Math::EaseOut(0.0, 1.0, Alpha, 2.0);
			HorizontalVelocity = Math::Lerp(HorizontalVelocity, HorizontalAlignedVelocity, Alpha);
		}
		// Uphill
		else if(SlopeDot < -KINDA_SMALL_NUMBER)
		{
			// reduce the velocity so we are going in a vertical direction
			// more than a horizontal direction, making us not
			// fly of edges in a high speed
			float Mul = Math::Lerp(1.0, 0.5, Alpha);
			HorizontalVelocity *= Mul;
			VerticalVelocity *= Mul;
		}
	}

}