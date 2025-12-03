
class UGenericGoatSprintCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Sprint);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 149;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerSprintComponent SprintComp;
	UPlayerFloorMotionComponent FloorMotionComp;
	UGenericGoatPlayerComponent GoatComp;

	float CurrentSpeed = 0.0;
	float NoInputTimer = 0.0;
	FVector Direction = FVector::ZeroVector;

	bool bCameraSettingsActive = false;

	UNiagaraComponent EffectComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
		FloorMotionComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
		GoatComp = UGenericGoatPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (bCameraSettingsActive)
		{
			if (IsBlocked()
				|| (!IsActive() && DeactiveDuration > SprintComp.Settings.CameraSettingsLingerTime)
				|| (!IsActive() && !SprintComp.IsSprintToggled())
			)
			{
				Player.ClearCameraSettingsByInstigator(this, 4.0);
				bCameraSettingsActive = false;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MoveComp.IsOnWalkableGround())
			return false;

		// This impulse will bring us up in the air, so dont activate
		if(MoveComp.HasUpwardsImpulse())
			return false;

		if (SprintComp.IsForcedToSprint())
			return true;

		if (!SprintComp.IsSprintToggled())
			return false;

		if (MoveComp.MovementInput.IsNearlyZero())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!MoveComp.IsOnWalkableGround())
			return true;

		if (MoveComp.HasUpwardsImpulse())
			return true;

		if (SprintComp.IsForcedToSprint())
			return false;

		if (!SprintComp.IsSprintToggled())
			return true;

		if (NoInputTimer >= 0.06)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Sprint, this);

		CurrentSpeed = MoveComp.HorizontalVelocity.Size();
		SprintComp.SetSprintActive(true);

		bCameraSettingsActive = true;
		// Player.ApplyCameraSettings(SprintComp.SprintCameraSetting, 2.0, this, FHazeCameraSettingsPriority(this));

		Direction = Player.ActorForwardVector;

		SprintComp.AnimData.bWantsToMove = false;
		NoInputTimer = 0.0;

		// EffectComp = Niagara::SpawnLoopingNiagaraSystemAttached(GoatComp.SprintSystem, GoatComp.CurrentGoat.GoatRoot);
		// EffectComp.SetRelativeLocation(FVector(0.0, 0.0, 75.0));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Sprint, this);

		SprintComp.SetSprintActive(false);

		// EffectComp.Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Record how long we haven't had any input
		// We don't stop the sprint immediately because it might be temporarily 0 when we want a turnaround!
		if (MoveComp.MovementInput.IsNearlyZero())
			NoInputTimer += DeltaTime;
		else
			NoInputTimer = 0.0;

		// Player.PlayCameraShake(SprintComp.SprintShake, 0.45);

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector TargetDirection = MoveComp.MovementInput;
				Direction = Math::VInterpConstantTo(Direction, TargetDirection, DeltaTime, 15.0);

				// Calculate the target speed
				float SpeedAlpha = Math::Clamp((MoveComp.MovementInput.Size() - SprintComp.Settings.MinimumInput) / (1.0 - SprintComp.Settings.MinimumInput), 0.0, 1.0);
				float TargetSpeed = Math::Lerp(SprintComp.Settings.MinimumSpeed, SprintComp.Settings.MaximumSpeed, SpeedAlpha) * MoveComp.MovementSpeedMultiplier * 1.8;
				if(MoveComp.MovementInput.IsNearlyZero())
					TargetSpeed = 0.0;
			
				// Update new velocity
				float InterpSpeed = SprintComp.Settings.Acceleration * MoveComp.MovementSpeedMultiplier * 3.0;
				if(TargetSpeed < CurrentSpeed)
					InterpSpeed = SprintComp.Settings.Deceleration * MoveComp.MovementSpeedMultiplier;
				CurrentSpeed = Math::FInterpConstantTo(MoveComp.HorizontalVelocity.Size(), TargetSpeed, DeltaTime, InterpSpeed);
				FVector HorizontalVelocity = Direction.GetSafeNormal() * CurrentSpeed;

				PrintToScreen("" + CurrentSpeed);

				Movement.AddHorizontalVelocity(HorizontalVelocity);
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();

				Movement.InterpRotationToTargetFacingRotation(SprintComp.Settings.FacingDirectionInterpSpeed);

				// Turn off the sprint when moving to slow
				float HorizontalVelSq = MoveComp.HorizontalVelocity.SizeSquared();
				if(HorizontalVelSq < Math::Square(50.0))
				{
					SprintComp.SetSprintActive(false);
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			SprintComp.AnimData.bWantsToMove = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();

			FName AnimTag = n"Movement";
			if(MoveComp.WasFalling())
				AnimTag = n"Landing";

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimTag);
		}
	}
}