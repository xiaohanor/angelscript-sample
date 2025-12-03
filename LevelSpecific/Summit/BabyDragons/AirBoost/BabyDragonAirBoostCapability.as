struct FBabyDragonAirBoostParams
{
	bool bBoost = false;
};

class UBabyDragonAirBoostCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::Dash);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	default CapabilityTags.Add(PlayerMovementTags::Jump);
	default CapabilityTags.Add(BabyDragon::BabyDragon);
	default CapabilityTags.Add(n"BabyDragonHover");

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 35;
	default TickGroupSubPlacement = 10;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerAirMotionComponent AirMotionComp;
	UPlayerAcidBabyDragonComponent DragonComp;
	UCameraUserComponent CameraUser;
	UPlayerFloorMotionComponent JogComp;
	UPlayerSprintComponent SprintComp;
	UPlayerRollDashComponent RollDashComp;

	bool bIsGliding = false;
	bool bHasLandedSinceLastBoost = true;
	FVector InitialDirection;
	float LastGlideTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
		DragonComp = UPlayerAcidBabyDragonComponent::Get(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);
		JogComp = UPlayerFloorMotionComponent::GetOrCreate(Player);
		SprintComp = UPlayerSprintComponent::GetOrCreate(Player);
		RollDashComp = UPlayerRollDashComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBabyDragonAirBoostParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (MoveComp.IsOnWalkableGround())
			return false;

		if (RollDashComp.bTriggeredRollDashJump)
			return false;

		if (IsActioning(ActionNames::SecondaryLevelAbility))
		{
			if (DragonComp.bInAirCurrent && Time::GetGameTimeSince(LastGlideTime) > 0.5)
				Params.bBoost = true;
			else if (bHasLandedSinceLastBoost)
				Params.bBoost = true;
			else
			{
				// We start gliding if we're still holding A while moving downward
				if (MoveComp.Velocity.Z > 0.0)
					return false;

				Params.bBoost = false;
			}

			// Do either a glide or an air jump followed by a glide
			return true;
		}
		else if (DragonComp.bInAirCurrent)
		{
			Params.bBoost = false;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (MoveComp.HasGroundContact())
			return true;

		if (MoveComp.HasCeilingContact())
			return true;

		if (MoveComp.HasImpulse())
			return true;

		if (!IsActioning(ActionNames::SecondaryLevelAbility) && ActiveDuration >= BabyDragonAirBoost::GlideMinimumDuration && Time::GetGameTimeSince(DragonComp.LastAirCurrentTime) > 1.0)
		{
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBabyDragonAirBoostParams Params)
	{
		Player.BlockCapabilities(BlockedWhileIn::Jump, this);
		bIsGliding = false;

		InitialDirection = Player.ActorForwardVector;

		UBabyDragonAirBoostEventHandler::Trigger_AirBoostActivated(Player);
		UBabyDragonAirBoostEventHandler::Trigger_AirBoostActivated(DragonComp.BabyDragon);

		// Add jump impulse if we still have one, otherwise glide until we release
		if (Params.bBoost)
		{
			LastGlideTime = Time::GameTimeSeconds;
			FVector VerticalVelocity;

			if (MoveComp.VerticalSpeed > 0)
			{
				if (MoveComp.VerticalVelocity.Size() > BabyDragonAirBoost::JumpImpulse)
					VerticalVelocity = MoveComp.VerticalVelocity;
				else
					VerticalVelocity = MoveComp.WorldUp * BabyDragonAirBoost::JumpImpulse;
			}
			else
				VerticalVelocity = MoveComp.WorldUp * BabyDragonAirBoost::JumpImpulse;

			FVector HorizontalVelocity = MoveComp.HorizontalVelocity;
			Player.SetActorHorizontalAndVerticalVelocity(HorizontalVelocity, VerticalVelocity);

			DragonComp.AnimationState.Apply(EAcidBabyDragonAnimationState::AirBoostDoubleJump, this);
		}
		else
		{
			DragonComp.AnimationState.Apply(EAcidBabyDragonAnimationState::Gliding, this);
		}
		bHasLandedSinceLastBoost = false;

		DragonComp.bIsGliding = true;

		Player.PlayForceFeedback(DragonComp.HoverFF, true, true, this, 1);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Jump, this);
		Player.ClearPointOfInterestByInstigator(this);

		if (WasActionStarted(ActionNames::Cancel))
			Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);

		DragonComp.AnimationState.Clear(this);

		if (bIsGliding)
		{
			bIsGliding = false;
			UBabyDragonAirBoostEventHandler::Trigger_StoppedGliding(Player);
			if(DragonComp.BabyDragon != nullptr)
				UBabyDragonAirBoostEventHandler::Trigger_StoppedGliding(DragonComp.BabyDragon);
		}
		Player.StopForceFeedback(this);

		DragonComp.bIsGliding = false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (MoveComp.IsOnWalkableGround())
			bHasLandedSinceLastBoost = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		if (MoveComp != nullptr)
		{
			float VerticalSpeed = MoveComp.VerticalSpeed;
			TemporalLog.Value("VerticalSpeed", VerticalSpeed);
			TemporalLog.Value("GlideUpwardsDeceleration", GetGlideUpwardsDeceleration(VerticalSpeed));
		}
	}

	float GetGlideUpwardsDeceleration(float VerticalSpeed) const
	{
		return BabyDragonAirBoost::GlideUpwardsDeceleration.GetMappedRangeValueClamped(VerticalSpeed, BabyDragonAirBoost::DecelerationSpeedRange);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				float TargetMovementSpeed = JogComp.Settings.MaximumSpeed + 150.0;
				if (SprintComp.IsSprintToggled())
					TargetMovementSpeed = SprintComp.Settings.MaximumSpeed;

				TargetMovementSpeed *= MoveComp.MovementSpeedMultiplier;

				float InterpSpeed = Math::Lerp(450.0, 1500.0, MoveComp.MovementInput.Size());
				FVector TargetSpeed = MoveComp.MovementInput * TargetMovementSpeed;
				FVector HorizontalVelocity = Math::VInterpConstantTo(MoveComp.HorizontalVelocity, TargetSpeed, DeltaTime, InterpSpeed);

				// if (MoveComp.MovementInput.Size() > 0.1)
				// {
				// 	if (!bHasRotated)
				// 	{
				// 		// If the input is being held in a different direction from the initial,
				// 		// we started rotating and the camera should follow.
				// 		if (MoveComp.MovementInput.GetSafeNormal2D().DotProduct(InitialDirection) < 0.8)
				// 			bHasRotated = true;
				// 	}
				// }

				Movement.AddHorizontalVelocity(HorizontalVelocity);

				float GravityMultiplier = BabyDragonAirBoost::GlideGravityMultiplier;

				FVector VerticalVelocity = MoveComp.VerticalVelocity;
				VerticalVelocity += MoveComp.GetGravity() * DeltaTime * GravityMultiplier;

				if (VerticalVelocity.Z < 0.0)
					VerticalVelocity = VerticalVelocity.GetClampedToMaxSize(BabyDragonAirBoost::GlideTerminalVelocity);
				else
				{
					VerticalVelocity.Z -= GetGlideUpwardsDeceleration(VerticalVelocity.Z) * DeltaTime;
				}

				Movement.AddVerticalVelocity(VerticalVelocity);
				Movement.InterpRotationToTargetFacingRotation(BabyDragonAirBoost::FacingDirectionInterpSpeed * MoveComp.MovementInput.Size());
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"BackpackDragonHover");
			DragonComp.RequestBabyDragonLocomotion(n"BackpackDragonHover");
		}

		if (!bIsGliding && Player.ActorVerticalVelocity.Z < 0.0)
		{
			bIsGliding = true;
			UBabyDragonAirBoostEventHandler::Trigger_StartedGliding(Player);
			DragonComp.AnimationState.Apply(EAcidBabyDragonAnimationState::Gliding, this);
		}
	}
}