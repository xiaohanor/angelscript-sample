class UTeenDragonUnwalkableSlideCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 150;

	UPlayerMovementComponent MoveComp;
	UTeenDragonMovementData Movement;

	UPlayerTeenDragonComponent DragonComp;

	UTeenDragonMovementSettings MovementSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Owner);
		DragonComp = UPlayerTeenDragonComponent::Get(Player);
		Movement = MoveComp.SetupMovementData(UTeenDragonMovementData);

		MovementSettings = UTeenDragonMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		
		if(!MoveComp.IsOnAnyGround())
			return false;

		if(MoveComp.IsOnWalkableGround())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!MoveComp.IsOnAnyGround())
			return true;

		if(MoveComp.IsOnWalkableGround())
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
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				Movement.AddOwnerVelocity();
				Movement.AddGravityAcceleration();
				Movement.InterpRotationToTargetFacingRotation(MovementSettings.AirFacingDirectionInterpSpeed * MoveComp.MovementInput.Size(), false);
			}
			else
			{
				// Follow the crumb trail on the remote side
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::AirMovement);
		}
	}
};