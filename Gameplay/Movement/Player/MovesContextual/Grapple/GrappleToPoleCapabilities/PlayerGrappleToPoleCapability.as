class UPlayerGrappleToPoleCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Grapple);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleMovement);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludeGrapple);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 4;
	default TickGroupSubPlacement = 8; 

	UPlayerMovementComponent MoveComp;
	UPlayerGrappleComponent GrappleComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;
	UPlayerAirMotionComponent AirMotionComp;
	UGrappleToPolePointComponent TargetedPoint;
	UPlayerPoleClimbComponent PoleClimbComp;

	USteppingMovementData Movement;

	bool bMoveCompleted = false;

	const float GRAPPLE_REEL_DURATION = 0.09;
	const float GRAPPLE_REEL_DELAY = 0.18;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		GrappleComp = UPlayerGrappleComponent::Get(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
		AirMotionComp = UPlayerAirMotionComponent::Get(Player);
		PoleClimbComp = UPlayerPoleClimbComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerGrappleToPointActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (GrappleComp.Data.CurrentGrapplePoint == nullptr)
			return false;

		if (GrappleComp.Data.CurrentGrapplePoint.GrappleType != EGrapplePointVariations::GrappleToPolePoint)
			return false;

		if (GrappleComp.Data.GrappleState != EPlayerGrappleStates::GrappleEnter)
			return false;

		if (!GrappleComp.Data.bEnterFinished)
			return false;

		auto GrapplePoint = Cast<UGrappleToPolePointComponent>(GrappleComp.Data.CurrentGrapplePoint);
		if(GrapplePoint == nullptr)
			return false;

		if(GrappleComp.Data.bGrappleToPointFinished)
			return false;
		
		Params.Data = GrappleComp.Data;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPlayerGrappleToPointDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
		{
			Params.bMoveCompleted = bMoveCompleted;
			return true;
		}

		if (MoveComp.HasCeilingContact() || MoveComp.HasWallContact())
			return true;

		if (GrappleComp.Data.CurrentGrapplePoint.IsDisabledForPlayer(Player))
            return true;

		if (bMoveCompleted)
		{
			Params.bMoveCompleted = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerGrappleToPointActivationParams Params)
	{
		Player.BlockCapabilities(BlockedWhileIn::Grapple, this);

		GrappleComp.Data = Params.Data;
		GrappleComp.Data.GrappleState = EPlayerGrappleStates::GrappleToPole;
		TargetedPoint = Cast<UGrappleToPolePointComponent>(GrappleComp.Data.CurrentGrapplePoint);
		MoveComp.FollowComponentMovement(TargetedPoint, this, EMovementFollowComponentType::Teleport);

		//Incase enter found any actors to ignore then maintain that throughout this move
		if(GrappleComp.Data.ActorsToIgnore.Num() > 0)
		{
			MoveComp.AddMovementIgnoresActors(this, GrappleComp.Data.ActorsToIgnore);
		}
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPlayerGrappleToPointDeactivationParams Params)
	{
		Player.UnblockCapabilities(BlockedWhileIn::Grapple, this);

		//Replicating status
		bMoveCompleted = Params.bMoveCompleted;

		//Should be fine to always unfollow as activation of next capability should perform its own follow		
		MoveComp.UnFollowComponentMovement(this);

		if (bMoveCompleted)
		{
			//Broadcast finished event from point and clean up
			if (IsValid(TargetedPoint))
			{
				if(TargetedPoint.PoleActor != nullptr)
					PoleClimbComp.ForceEnterPole(TargetedPoint.PoleActor, bSnapCamera = false);

				TargetedPoint.OnPlayerFinishedGrapplingToPointEvent.Broadcast(Player, TargetedPoint);
			}
		}	
		else
		{
			// Broadcast interrupted event
			if (IsValid(TargetedPoint))
				TargetedPoint.OnPlayerInterruptedGrapplingToPointEvent.Broadcast(Player, TargetedPoint);

			// Don't allow premature canceling to overspeed
			FVector HorizontalVelocity = Player.GetActorHorizontalVelocity().GetClampedToMaxSize(AirMotionComp.Settings.HorizontalMoveSpeed);
			FVector VerticalVelocity = bMoveCompleted ? FVector::ZeroVector : Player.GetActorVerticalVelocity();
			Player.SetActorVelocity(HorizontalVelocity + VerticalVelocity);
		}

		GrappleComp.Grapple.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
		GrappleComp.Grapple.SetActorHiddenInGame(true);

		//reset all the grapple data
		GrappleComp.Data.ResetData();
		GrappleComp.AnimData.ResetData();

		// Clear point for targeting by player again
		if (IsValid(TargetedPoint))
			TargetedPoint.ClearPointForPlayer(Player);

		TargetedPoint = nullptr;

		bMoveCompleted = false;

		MoveComp.RemoveMovementIgnoresActor(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				float Speed = Math::Lerp(0, GrappleComp.Settings.GrappleToPointTopVelocity, GrappleComp.AccelerationCurve.GetFloatValue(ActiveDuration / GrappleComp.Settings.GrappleToPointAccelerationDuration));

				FVector Direction = GrappleComp.Data.GrappleToPointWorldTargetLocation - Player.ActorLocation;
				Direction = Direction.GetSafeNormal();

				FVector FrameDeltaMove = Direction * Speed * DeltaTime;

				float ToPointDelta = (GrappleComp.Data.GetGrappleToPointWorldTargetLocation() - Player.ActorLocation).Size();
				if(ToPointDelta <= 500)
				{
					GrappleComp.AnimData.bAnticipatePoleLanding = true;
				}

				if(FrameDeltaMove.Size() > (GrappleComp.Data.GrappleToPointWorldTargetLocation - Player.ActorLocation).Size() || (GrappleComp.Data.GrappleToPointWorldTargetLocation - Player.ActorLocation).Size() <= 10)
				{
					FrameDeltaMove = (GrappleComp.Data.GrappleToPointWorldTargetLocation - Player.ActorLocation);
					bMoveCompleted = true;
					GrappleComp.Data.bGrappleToPointFinished = true;
				}

				Movement.OverrideStepUpAmountForThisFrame(50);
				Movement.SetRotation(Player.ActorRotation);
				Movement.AddDeltaWithCustomVelocity(FrameDeltaMove, FrameDeltaMove.GetSafeNormal() * Speed);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Grapple");

			GrappleComp.RetractGrapple(ActiveDuration);
		}
	}

	bool VerifyIfAboveTarget() const
	{
		FVector Direction = (GrappleComp.Data.CurrentGrapplePoint.WorldLocation - Player.ActorLocation).GetSafeNormal();
		float WorldUpDirectonDot = MoveComp.WorldUp.DotProduct(Direction);

		return WorldUpDirectonDot < 0;
	}
};