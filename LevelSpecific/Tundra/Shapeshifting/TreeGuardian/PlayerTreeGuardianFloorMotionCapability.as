class UTundraPlayerTreeGuardianFloorMotionCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::FloorMotion);
	default CapabilityTags.Add(PlayerFloorMotionTags::FloorMotionMovement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 150;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UTundraPlayerTreeGuardianComponent TreeGuardianComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	
	UTundraPlayerTreeGuardianSettings Settings;

	float CurrentSpeed = 0.0;
	FVector AdditionalVelocity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		Settings = UTundraPlayerTreeGuardianSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		
		// // This impulse will bring us up in the air, so don't activate
		if (!MoveComp.IsOnWalkableGround() || MoveComp.HasUpwardsImpulse())
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

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::FloorMotion, this);

		CurrentSpeed = Player.ActorForwardVector.DotProduct(MoveComp.HorizontalVelocity);
		CurrentSpeed = Math::Max(CurrentSpeed, 0.0);
		AdditionalVelocity = MoveComp.HorizontalVelocity - (Player.ActorForwardVector * CurrentSpeed);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::FloorMotion, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector TargetDirection = MoveComp.MovementInput;
				float InputSize = MoveComp.MovementInput.Size();

				// While on edges, we force the player of them.
				if (TargetDirection.IsNearlyZero())
				{
					TargetDirection = Player.ActorForwardVector;
				}

				// Interp from current forward to target forward
				const FQuat CurrentForward = FQuat::MakeFromZX(Player.ActorUpVector, Player.ActorForwardVector);
				const FQuat TargetForward = FQuat::MakeFromZX(Player.ActorUpVector, TargetDirection);
				const FQuat NewRotation = Math::QInterpTo(CurrentForward, TargetForward, DeltaTime, PI * Settings.TurnMultiplier);

				// Calculate the target speed
				float SpeedAlpha = Math::Clamp((InputSize - Settings.MinimumInput) / (1.0 - Settings.MinimumInput), 0.0, 1.0);
				float TargetSpeed = Math::Lerp(Settings.MinimumSpeed, Settings.MaximumSpeed, SpeedAlpha) * MoveComp.MovementSpeedMultiplier;

				if(InputSize < KINDA_SMALL_NUMBER)
					TargetSpeed = 0.0;
			
				// Update new velocity
				float SpeedAcceleration = Settings.Acceleration;
				if (CurrentSpeed > TargetSpeed)
					SpeedAcceleration = Settings.Deceleration;

				CurrentSpeed = Math::FInterpConstantTo(CurrentSpeed, TargetSpeed, DeltaTime, SpeedAcceleration);

				FVector HorizontalVelocity = NewRotation.ForwardVector * CurrentSpeed;

				AdditionalVelocity += MoveComp.GetPendingImpulse();
				AdditionalVelocity += TreeGuardianComp.GetFrameRateIndependentDrag(AdditionalVelocity, 8.0, DeltaTime);
				Movement.AddVelocity(AdditionalVelocity);
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.AddHorizontalVelocity(HorizontalVelocity);

				Movement.SetRotation(NewRotation);
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			FName AnimTag = FeatureName::Movement;
			if (MoveComp.WasFalling())
			{
				AnimTag = n"Landing";

				if(Player.Mesh.CanRequestAdditiveFeature())
					Player.Mesh.RequestAdditiveFeature(n"LandingAdditive", this);

				UPlayerCoreMovementEffectHandler::Trigger_Landed(Player);
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, AnimTag);
		}
	}
}