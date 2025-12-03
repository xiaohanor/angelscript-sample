
class UPlayerCrouchCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Crouch);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 2;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UPlayerSprintComponent SprintComp;
	USteppingMovementData Movement;
	
	UPlayerCrouchComponent CrouchComp;
	UPlayerLandingComponent LandingComp;

	float CurrentSpeed = 0.0;
	FVector Direction = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		CrouchComp = UPlayerCrouchComponent::GetOrCreate(Player);
		LandingComp = UPlayerLandingComponent::GetOrCreate(Player);
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		
		// // This impulse will bring us up in the air, so dont activate
		if (!MoveComp.IsOnWalkableGround() || MoveComp.HasUpwardsImpulse())
			return false;

		if (!CrouchComp.bCrouching)
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

		if (!CrouchComp.bCrouching)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Crouch, this);

		CurrentSpeed = MoveComp.HorizontalVelocity.Size();
		Direction = Player.ActorForwardVector;

		LandingComp.AnimData.State = EPlayerLandingState::Standard;
		Player.CapsuleComponent.OverrideCapsuleHalfHeight(CrouchComp.Settings.CapsuleHalfHeight, this);
		Player.CapsuleComponent.OverrideCapsuleRadius(45, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Crouch, this);
		Player.CapsuleComponent.ClearCapsuleSizeOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{	
				FVector TargetDirection = MoveComp.MovementInput;
				Direction = Math::VInterpConstantTo(Direction, TargetDirection, DeltaTime, 15.0);

				// Calculate the target speed
				float SpeedAlpha = Math::Clamp((MoveComp.MovementInput.Size() - CrouchComp.Settings.MinimumInput) / (1.0 - CrouchComp.Settings.MinimumInput), 0.0, 1.0);
				//float TargetSpeed = Math::Lerp(FloorMotionComp.Settings.MinimumSpeed, FloorMotionComp.Settings.MaximumSpeed, SpeedAlpha);
				float TargetSpeed =  CrouchComp.GetMovementTargetSpeed(SpeedAlpha, SprintComp.IsSprintToggled());
				if(MoveComp.MovementInput.IsNearlyZero())
					TargetSpeed = 0.0;
			
				TargetSpeed *= MoveComp.MovementSpeedMultiplier;

				// Update new velocity
				float InterpSpeed = CrouchComp.Settings.AccelerateInterpSpeed;
				if(TargetSpeed < CurrentSpeed)
					InterpSpeed = CrouchComp.Settings.SlowDownInterpSpeed;
				CurrentSpeed = Math::FInterpTo(MoveComp.HorizontalVelocity.Size(), TargetSpeed, DeltaTime, InterpSpeed);
				FVector HorizontalVelocity = Direction.GetSafeNormal() * CurrentSpeed;
	
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.AddHorizontalVelocity(HorizontalVelocity);

				Movement.InterpRotationToTargetFacingRotation(CrouchComp.Settings.FacingDirectionInterpSpeed);
#if !RELEASE
				if (IsDebugActive())
				{
					PrintToScreenScaled("Vel: " + Player.GetActorRotation().UnrotateVector(MoveComp.HorizontalVelocity) + " | " + Math::RoundToFloat(MoveComp.HorizontalVelocity.Size()));
					PrintToScreenScaled("SpeedAlpha: " + SpeedAlpha);
					PrintToScreenScaled("TargetSpeed: " + TargetSpeed);
				}
#endif
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			FName AnimTag = n"Crouch";
			if (MoveComp.WasFalling())
			{
				AnimTag = n"Landing";

				UPlayerCoreMovementEffectHandler::Trigger_Landed(Player);
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimTag);

		}
	}
};