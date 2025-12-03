class UTeenDragonDashCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonDash);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::ActionMovement;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UHazeMovementComponent MoveComp;
	UTeenDragonMovementData Movement;
	UPlayerTeenDragonComponent DragonComp;

	UTeenDragonMovementSettings MovementSettings;

	float CurrentSpeed = 0.0;
	FVector Direction = FVector::ZeroVector;
	float TimeOfLastDashEnd = -100.0;

	bool bPlayedDashLandingRumble;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Player);
		DragonComp = UPlayerTeenDragonComponent::Get(Player);
		Movement = MoveComp.SetupMovementData(UTeenDragonMovementData);

		MovementSettings = UTeenDragonMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!MoveComp.IsOnWalkableGround() || MoveComp.HasUpwardsImpulse())
			return false;

		if(!WasActionStarted(ActionNames::MovementDash))
			return false;

		if(Time::GetGameTimeSeconds() - TimeOfLastDashEnd < MovementSettings.DashCooldown)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!MoveComp.IsOnWalkableGround() || MoveComp.HasUpwardsImpulse())
			return true;

		if(ActiveDuration > MovementSettings.DashDuration)
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

		if (!DragonComp.bTopDownMode) {
			// Player.ApplyCameraSettings(DragonComp.SprintCameraSettings, 2, this, SubPriority = 55);
			// UCameraSettings::GetSettings(Player).FOV.Apply(77.0, this, 2, SubPriority = 55);
		}
		DragonComp.bIsDashing = true;
		CurrentSpeed = MovementSettings.DashSpeed * MoveComp.MovementSpeedMultiplier;

		Player.PlayForceFeedback(DragonComp.DashRumble, false, true, this, 0.5);
		bPlayedDashLandingRumble = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(BlockedWhileIn::FloorMotion, this);		
		Player.ClearCameraSettingsByInstigator(this, 1.0);
		DragonComp.AnimationState.Clear(this);
		DragonComp.bIsDashing = false;
		TimeOfLastDashEnd = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{	
				FVector TargetDirection = MoveComp.MovementInput;

				// While on edges, we force the player of them.
				if (TargetDirection.IsNearlyZero())
				{
					TargetDirection = Player.ActorForwardVector;
				}

				Direction = Math::QInterpConstantTo(Direction.ToOrientationQuat(), TargetDirection.ToOrientationQuat(), DeltaTime, PI * 2.0).ForwardVector;

				CurrentSpeed = Math::Max(CurrentSpeed - MovementSettings.DashDeceleration * DeltaTime, 0.0);
	
				FVector HorizontalVelocity = Direction.GetSafeNormal() * CurrentSpeed;
	
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.AddHorizontalVelocity(HorizontalVelocity);
				//Movement.ApplyMaxEdgeDistanceUntilUnwalkable(FMovementSettingsValue::MakePercentage(0.25));

				Movement.SetRotation(Direction.ToOrientationQuat());
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::DragonDash);
		}

		if (ActiveDuration > MovementSettings.DashDuration - 0.2 && !bPlayedDashLandingRumble)
		{
			Player.PlayForceFeedback(DragonComp.DashRumble, false, true, this, 0.5);
			bPlayedDashLandingRumble = true;
		}
	}
}