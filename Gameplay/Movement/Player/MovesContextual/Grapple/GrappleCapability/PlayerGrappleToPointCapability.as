struct FPlayerGrappleToPointActivationParams
{
	FPlayerGrappleData Data;
}

struct FPlayerGrappleToPointDeactivationParams
{
	bool bMoveCompleted = false;
}

class UPlayerGrappleToPointCapability : UHazePlayerCapability
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
	default TickGroupSubPlacement = 6; 

	/**
	 * This capability currently handles all 3 variations of GrappleToPoint (Above/Straight/Below), but the target location will be modified based on the angle diff
	 */

	UPlayerMovementComponent MoveComp;
	UPlayerGrappleComponent GrappleComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;
	UPlayerAirMotionComponent AirMotionComp;
	UGrapplePointComponent TargetedPoint;

	USteppingMovementData Movement;

	bool bMoveCompleted = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		GrappleComp = UPlayerGrappleComponent::Get(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
		AirMotionComp = UPlayerAirMotionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerGrappleToPointActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (GrappleComp.Data.CurrentGrapplePoint == nullptr)
			return false;
		
		if (GrappleComp.Data.CurrentGrapplePoint.GrappleType != EGrapplePointVariations::GrapplePoint)
			return false;

		if (GrappleComp.Data.GrappleState != EPlayerGrappleStates::GrappleEnter)
			return false;

		if (!GrappleComp.Data.bEnterFinished)
			return false;

		auto GrapplePoint = Cast<UGrapplePointComponent>(GrappleComp.Data.CurrentGrapplePoint);
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
		TargetedPoint = Cast<UGrapplePointComponent>(GrappleComp.Data.CurrentGrapplePoint);
		MoveComp.FollowComponentMovement(TargetedPoint, this, EMovementFollowComponentType::Teleport);

		if(GrappleComp.Data.bLedgeExit)
		{
			GrappleComp.Data.GrappleState = EPlayerGrappleStates::GrappleToPoint;
		}
		else
		{
			GrappleComp.Data.GrappleState = EPlayerGrappleStates::GrappleToPointGrounded;
		}

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
				TargetedPoint.OnPlayerFinishedGrapplingToPointEvent.Broadcast(Player, TargetedPoint);

			if(!GrappleComp.Data.bLedgeExit)
			{
				MoveComp.FindGround(20);

				if(GrappleComp.Data.bFailedToDetectValidExit)
				{
					//Just incase we didnt find a valid ledge or ground exit and we simply cancelled out to Air/GroundMotion
					if (IsValid(TargetedPoint))
						TargetedPoint.ClearPointForPlayer(Player);
					TargetedPoint = nullptr;

					GrappleComp.Data.ResetData();
					GrappleComp.AnimData.ResetData();
				}
			}
		}
		else
		{
			// Broadcast interrupted event
			if (IsValid(TargetedPoint))
				TargetedPoint.OnPlayerInterruptedGrapplingToPointEvent.Broadcast(Player, TargetedPoint);

			// If we were interrupted, reset all the grapple data
			GrappleComp.Data.ResetData();
			GrappleComp.AnimData.ResetData();

			// Clear point for targeting by player again
			if (IsValid(TargetedPoint))
				TargetedPoint.ClearPointForPlayer(Player);
			TargetedPoint = nullptr;
		}

		// Don't allow premature canceling to overspeed
		FVector HorizontalVelocity = Player.GetActorHorizontalVelocity().GetClampedToMaxSize(AirMotionComp.Settings.HorizontalMoveSpeed);
		FVector VerticalVelocity = bMoveCompleted ? FVector::ZeroVector : Player.GetActorVerticalVelocity();
		Player.SetActorVelocity(HorizontalVelocity + VerticalVelocity);

		bMoveCompleted = false;

		GrappleComp.Grapple.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
		GrappleComp.Grapple.SetActorHiddenInGame(true);

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