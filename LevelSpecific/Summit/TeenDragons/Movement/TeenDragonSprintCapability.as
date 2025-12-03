
class UTeenDragonSprintCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonSprint);	

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 149;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UHazeMovementComponent MoveComp;
	UTeenDragonMovementData Movement;

	UPlayerTeenDragonComponent DragonComp;

	UTeenDragonMovementSettings MovementSettings;
	
	float CurrentSpeed = 0.0;
	FVector Direction = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupMovementData(UTeenDragonMovementData);

		DragonComp = UPlayerTeenDragonComponent::Get(Player);

		MovementSettings = UTeenDragonMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!IsBlocked())
		{
			if(DragonComp.bTopDownMode)
			{
				DragonComp.bIsSprinting = true;
			}
			else
			{
				if (WasActionStarted(ActionNames::MovementSprint))
					DragonComp.bIsSprinting = !DragonComp.bIsSprinting;
				if (MoveComp.MovementInput.Size() < 0.5)
					DragonComp.bIsSprinting = false;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (!MoveComp.IsOnWalkableGround() || MoveComp.HasUpwardsImpulse())
			return false;
		if (!DragonComp.bIsSprinting)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (!MoveComp.IsOnWalkableGround() || MoveComp.HasUpwardsImpulse())
			return true;
		if (!DragonComp.bIsSprinting)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(BlockedWhileIn::FloorMotion, this);

		CurrentSpeed = MoveComp.HorizontalVelocity.Size();
		Direction = Owner.ActorForwardVector;
		DragonComp.AnimationState.Apply(ETeenDragonAnimationState::Sprint, this);

		if (!DragonComp.bTopDownMode) 
		{
			Player.PlayCameraShake(DragonComp.SprintContinuousCameraShake, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(BlockedWhileIn::FloorMotion, this);

		Player.StopCameraShakeByInstigator(this);
		DragonComp.AnimationState.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{	
				FVector TargetDirection = MoveComp.MovementInput;
				float InputSize = MoveComp.MovementInput.Size();

				// While on edges, we force the player of them.
				if (TargetDirection.IsNearlyZero())
				{
					TargetDirection = Player.ActorForwardVector;
				}

				Direction = Math::QInterpConstantTo(Direction.ToOrientationQuat(), TargetDirection.ToOrientationQuat(), DeltaTime, PI * 2.0).ForwardVector;

				// Calculate the target speed
				float SpeedAlpha = Math::Clamp((InputSize - MovementSettings.MinimumInput) / (1.0 - MovementSettings.MinimumInput), 0.0, 1.0);
				float TargetSpeed = Math::Lerp(MovementSettings.MaximumSpeed, MovementSettings.SprintSpeed, SpeedAlpha) * MoveComp.MovementSpeedMultiplier;

				if(InputSize < KINDA_SMALL_NUMBER)
					TargetSpeed = 0.0;
			
				// Update new velocity
				float SpeedAcceleration = MovementSettings.AccelerationInterpSpeed;
				if (CurrentSpeed > TargetSpeed)
					SpeedAcceleration = MovementSettings.SlowDownInterpSpeed;

				CurrentSpeed = Math::FInterpTo(MoveComp.HorizontalVelocity.Size(), TargetSpeed, DeltaTime, SpeedAcceleration);

				FVector HorizontalVelocity = Direction.GetSafeNormal() * CurrentSpeed;
				
				Movement.AddPendingImpulses();
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.AddHorizontalVelocity(HorizontalVelocity);

				Movement.SetRotation(Direction.ToOrientationQuat());
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			FName AnimTag = TeenDragonLocomotionTags::Movement;
			if(MoveComp.WasFalling())
				AnimTag = TeenDragonLocomotionTags::Landing;

			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(AnimTag);
		}
	}


};