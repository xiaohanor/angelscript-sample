struct FTeenDragonSlowdownDeactivationParams
{
	bool bSlowdownFinished = false;
};

class UTeenDragonFloorSlowdownCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 148;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UTeenDragonMovementData Movement;

	UPlayerTeenDragonComponent DragonComp;

	UTeenDragonMovementSettings MovementSettings;

	float CurrentSpeed;
	FVector Dir;
	FVector StartVelocity;
	FVector StartLoc;
	FVector EndLoc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupMovementData(UTeenDragonMovementData);

		DragonComp = UPlayerTeenDragonComponent::Get(Player);

		MovementSettings = UTeenDragonMovementSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MoveComp.IsOnWalkableGround())
			return false;

		if(MoveComp.HasUnstableGroundContactEdge())
			return false;

		// This impulse will bring us up in the air, so dont activate
		if(MoveComp.HasUpwardsImpulse())
			return false;

		if (!MoveComp.MovementInput.IsNearlyZero())
			return false;

		if (MoveComp.HorizontalVelocity.IsNearlyZero(25.0))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FTeenDragonSlowdownDeactivationParams& DeactivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!MoveComp.IsOnWalkableGround())
			return true;

		if (!MoveComp.MovementInput.IsNearlyZero())
			return true;

		if (MoveComp.HasUpwardsImpulse())
			return true;

		if (ActiveDuration >= MovementSettings.FloorSlowdownDuration)
		{
			DeactivationParams.bSlowdownFinished = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(BlockedWhileIn::FloorMotion, this);
		CurrentSpeed = MoveComp.HorizontalVelocity.Size();

		StartVelocity = MoveComp.HorizontalVelocity + MoveComp.HorizontalVelocity.GetSafeNormal() * MoveComp.PreviousVerticalVelocity.Size() * 0.2;
		StartLoc = Player.ActorLocation;
		EndLoc = (StartVelocity * MovementSettings.FloorSlowdownDuration) / 2;
		EndLoc += StartLoc;
		
		Dir = MoveComp.HorizontalVelocity.GetSafeNormal();
		if (Dir.IsNearlyZero() || MoveComp.WasInAir())
			Dir = Player.ActorForwardVector;
		
		Player.SetMovementFacingDirection(Dir);
		DragonComp.AnimationState.Apply(ETeenDragonAnimationState::FloorSlowdown, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTeenDragonSlowdownDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(BlockedWhileIn::FloorMotion, this);
		DragonComp.AnimationState.Clear(this);

		if (DeactivationParams.bSlowdownFinished)
			Player.SetActorHorizontalVelocity(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.SetMovementFacingDirection(Dir);

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				float Alpha = ActiveDuration / MovementSettings.FloorSlowdownDuration;
				Alpha = Math::Clamp(Alpha, 0.0, 1.0);
				FVector Velocity = Math::Lerp(StartVelocity, FVector::ZeroVector, Alpha);

				Movement.AddHorizontalVelocity(Velocity);
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.InterpRotationToTargetFacingRotation(20.0);

				Movement.StopMovementWhenLeavingEdgeThisFrame();
				Movement.BlockStepUpForThisFrame();
			}
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