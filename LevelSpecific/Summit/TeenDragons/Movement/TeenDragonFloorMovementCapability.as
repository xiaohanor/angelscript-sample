
class UTeenDragonFloorMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);	

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 150;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UTeenDragonMovementData Movement;

	UPlayerTeenDragonComponent DragonComp;

	UTeenDragonMovementSettings MovementSettings;
	
	float CurrentSpeed = 0.0;

	bool bResetDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Owner);
		Movement = MoveComp.SetupMovementData(UTeenDragonMovementData);

		DragonComp = UPlayerTeenDragonComponent::Get(Player);

		MovementSettings = UTeenDragonMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		
		// // This impulse will bring us up in the air, so dont activate
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
		Owner.BlockCapabilities(BlockedWhileIn::FloorMotion, this);

		CurrentSpeed = MoveComp.HorizontalVelocity.Size();
		DragonComp.AnimationState.Apply(ETeenDragonAnimationState::FloorMovement, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.UnblockCapabilities(BlockedWhileIn::FloorMotion, this);		
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

				// Interp from current forward to target forward
				const FQuat CurrentForward = FQuat::MakeFromZX(Player.ActorUpVector, Player.ActorForwardVector);
				const FQuat TargetForward = FQuat::MakeFromZX(Player.ActorUpVector, TargetDirection);
				const FQuat NewRotation = Math::QInterpTo(CurrentForward, TargetForward, DeltaTime, PI * MovementSettings.TurnMultiplier);

				// Calculate the target speed
				float SpeedAlpha = Math::Clamp((InputSize - MovementSettings.MinimumInput) / (1.0 - MovementSettings.MinimumInput), 0.0, 1.0);
				float TargetSpeed = Math::Lerp(MovementSettings.MinimumSpeed, MovementSettings.MaximumSpeed, SpeedAlpha) * MoveComp.MovementSpeedMultiplier;

				if(InputSize < KINDA_SMALL_NUMBER)
					TargetSpeed = 0.0;
			
				// Update new velocity
				float SpeedAcceleration = MovementSettings.AccelerationInterpSpeed;
				if (CurrentSpeed > TargetSpeed)
					SpeedAcceleration = MovementSettings.SlowDownInterpSpeed;

				CurrentSpeed = Math::FInterpTo(MoveComp.HorizontalVelocity.Size(), TargetSpeed, DeltaTime, SpeedAcceleration);
	
				FVector HorizontalVelocity = NewRotation.ForwardVector * CurrentSpeed;

				Movement.AddPendingImpulses();
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

			FName AnimTag = TeenDragonLocomotionTags::Movement;
			if(MoveComp.WasFalling())
				AnimTag = TeenDragonLocomotionTags::Landing;

			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(AnimTag);
		}
	}
};