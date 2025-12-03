class UTeenDragonAirMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 160;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UPlayerTeenDragonComponent DragonComp;
	UTeenDragonMovementData Movement;

	UTeenDragonJumpSettings JumpSettings;
	UTeenDragonMovementSettings MovementSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Owner);
		DragonComp = UPlayerTeenDragonComponent::Get(Player);
		Movement = MoveComp.SetupMovementData(UTeenDragonMovementData);

		JumpSettings = UTeenDragonJumpSettings::GetSettings(Player);
		MovementSettings = UTeenDragonMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DragonComp.AnimationState.Apply(ETeenDragonAnimationState::AirMovement, this);
		Owner.BlockCapabilities(BlockedWhileIn::AirMotion, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.AnimationState.Clear(this);
		Owner.UnblockCapabilities(BlockedWhileIn::AirMotion, this);
		Player.PlayForceFeedback(DragonComp.JumpRumble, false, true, this, 0.3);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				float InputSize = MoveComp.MovementInput.Size();

				FVector HorizontalVelocity = MoveComp.HorizontalVelocity;

				// Calculate the target speed
				float SpeedAlpha = Math::Clamp((InputSize - MovementSettings.MinimumInput) / (1.0 - MovementSettings.MinimumInput), 0.0, 1.0);
				float TargetSpeed = Math::Lerp(MovementSettings.AirHorizontalMinMoveSpeed, MovementSettings.AirHorizontalMaxMoveSpeed, SpeedAlpha) * MoveComp.MovementSpeedMultiplier;

				float InterpSpeed = MovementSettings.AirHorizontalVelocityAccelerationWithInput;
				float HorizontalSpeed = HorizontalVelocity.Size();
				if(HorizontalSpeed > MovementSettings.AirHorizontalMaxMoveSpeed)
				{
					InterpSpeed = MovementSettings.AirHorizontalVelocityDecelerationWhenOverSpeed;
				}
				else if (InputSize < KINDA_SMALL_NUMBER)
				{
					TargetSpeed = 0.0;
					InterpSpeed = MovementSettings.AirHorizontalVelocityAccelerationWithoutInput;
				}

				FVector TargetDirection = MoveComp.MovementInput.GetSafeNormal();

				HorizontalVelocity = Math::VInterpTo(HorizontalVelocity, TargetDirection * TargetSpeed, DeltaTime, InterpSpeed);
				Movement.AddHorizontalVelocity(HorizontalVelocity);
				Movement.AddOwnerVerticalVelocity();
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
			DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::AirMovement);
		}
	}
}