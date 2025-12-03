struct FPlayerLadderDashActivationParams
{
	bool bIsExitOnTop = false;
	FLadderRung TargetRung;
}

class UPlayerLadderDashCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Ladder);
	default CapabilityTags.Add(PlayerLadderTags::LadderClimbUp);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 21;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData Movement;
	UPlayerLadderComponent LadderComp;

	float CurrentCooldown = 0.0;
	bool bIsDashExitOnTop = false;

	FDashMovementCalculator DashCalculator;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
		LadderComp = UPlayerLadderComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		CurrentCooldown += DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerLadderDashActivationParams& ActivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (LadderComp.Data.ActiveLadder == nullptr)
			return false;

		if(LadderComp.Data.ActiveLadder.IsDisabled())
			return false;

		if (CurrentCooldown < LadderComp.Settings.LadderDashCooldown)
			return false;

		if (!WasActionStarted(ActionNames::MovementDash))
			return false;

		ALadder Ladder = LadderComp.Data.ActiveLadder;
		FVector TargetLocation = Player.ActorLocation + Ladder.ActorUpVector * LadderComp.Settings.LadderDashDistance;
		FLadderRung TargetRung = Ladder.GetClosestRungToWorldLocation(TargetLocation);
		FVector TargetRungLocation = Ladder.GetRungWorldLocation(TargetRung);

		float RealDistance = Math::Abs((TargetRungLocation - Player.ActorLocation).DotProduct(Ladder.ActorUpVector));

		// If our dash distance would be too small, we aren't allowed to dash.
		// This can happen at the top of a ladder that blocks climb-out
		if (RealDistance < 50.0 && Ladder.bBlockClimbingOutTop)
			return false;
		
		if (!TestCollisionForDash(TargetRung))
			return false;

		ActivationParams.TargetRung = TargetRung;
		ActivationParams.bIsExitOnTop = (TargetRung == Ladder.GetTopRung()) && RealDistance <= LadderComp.Settings.LadderDashDistance && !Ladder.bBlockClimbingOutTop;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (LadderComp.Data.ActiveLadder == nullptr)
			return true;

		if (DashCalculator.IsFinishedAtTime(ActiveDuration))
			return true;

		// If the dash is currently _decelerating_, but we are holding the input to go up,
		// and we've already decelerated sufficiently to our normal speed, the dash should finish.
		// This way we don't go down to 0 velocity unnecessarily and things will be smoother
		if (DashCalculator.IsDeceleratingAtTime(ActiveDuration))
		{
			FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
			if (MoveInput.Y > 0.0)
			{
				float TargetVerticalSpeed = LadderComp.Settings.ClimbUpSpeed;
				float CurrentSpeed = DashCalculator.GetSpeedAtTime(ActiveDuration);
				if (CurrentSpeed <= TargetVerticalSpeed)
					return true;
			}
		}

		// If we ever end up dashing above the last rung of the ladder, exit out
		// This should only happen if we're doing a dash-into-exit
		ALadder Ladder = LadderComp.Data.ActiveLadder;
		FLadderRung TopRung = Ladder.GetTopRung();
		FVector TopRungLocation = Ladder.GetRungWorldLocation(TopRung);
		float HeightToTopRung = (Player.ActorLocation - TopRungLocation).DotProduct(Ladder.ActorUpVector);
		if (HeightToTopRung > 1.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerLadderDashActivationParams ActivationParams)
	{
		Player.BlockCapabilities(BlockedWhileIn::Ladder, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);

		LadderComp.SetState(EPlayerLadderState::Dash);
		LadderComp.Data.bMoving = true;

		ALadder Ladder = LadderComp.Data.ActiveLadder;
		
		FLadderRung TargetRung = ActivationParams.TargetRung;

		FVector TargetRungLocation = Ladder.GetRungWorldLocation(TargetRung);

		float CurrentSpeed = Ladder.ActorUpVector.DotProduct(MoveComp.Velocity);
		float RealDistance = Math::Abs((TargetRungLocation - Player.ActorLocation).DotProduct(Ladder.ActorUpVector));

		bIsDashExitOnTop = ActivationParams.bIsExitOnTop;
		if (bIsDashExitOnTop)
			RealDistance = LadderComp.Settings.LadderDashDistance;

		DashCalculator = FDashMovementCalculator(
			GetCapabilityDeltaTime(),
			RealDistance,
			LadderComp.Settings.LadderDashDuration,
			LadderComp.Settings.LadderDashAccelerationDuration,
			LadderComp.Settings.LadderDashDecelerationDuration,
			CurrentSpeed, 0.0
		);

		Player.SetActorVelocity(FVector::ZeroVector);

		Player.PlayForceFeedback(LadderComp.DashFF, false, true, this);

		UPlayerCoreMovementEffectHandler::Trigger_Ladder_Dash_Started(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Ladder, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);
		CurrentCooldown = 0.0;

		if (bIsDashExitOnTop)
			LadderComp.bTriggerExitOnTop = true;

		LadderComp.Data.bMoving = false;

		UPlayerCoreMovementEffectHandler::Trigger_Ladder_Dash_Finished(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{		
				Movement.SetRotation(LadderComp.CalculatePlayerCapsuleRotation(LadderComp.Data.ActiveLadder));

				float FrameMovement;
				float FrameSpeed;

				DashCalculator.CalculateMovement(
					ActiveDuration, DeltaTime,
					FrameMovement, FrameSpeed
				);

				Movement.AddDeltaWithCustomVelocity(
					LadderComp.Data.ActiveLadder.ActorUpVector * FrameMovement,
					LadderComp.Data.ActiveLadder.ActorUpVector * FrameSpeed,
					EMovementDeltaType::Native
				);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"LadderClimb", this);
		}
	}

	bool TestCollisionForDash(FLadderRung TargetRung) const
	{
		FHazeTraceSettings CollisionTrace = Trace::InitFromMovementComponent(MoveComp);
		CollisionTrace.UseLine();

		FVector StartLocation = Player.ActorLocation;
		FVector EndLocation = LadderComp.Data.ActiveLadder.GetRungWorldLocation(TargetRung);
		EndLocation += LadderComp.Data.ActiveLadder.ActorUpVector * (Player.ScaledCapsuleHalfHeight * 2);

		FHitResult CollisionHit = CollisionTrace.QueryTraceSingle(StartLocation, EndLocation);

		if(CollisionHit.bBlockingHit)
			return false;

		return true;
	}
};

