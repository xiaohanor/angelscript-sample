class UPlayerGrappleToPointAirExitCapability : UHazePlayerCapability
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
	default TickGroupSubPlacement = 4; 

	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;

	UPlayerGrappleComponent GrappleComp;
	UPlayerFloorMotionComponent FloorMotionComp;
	UPlayerAirMotionComponent AirMotionComp;

	UGrapplePointComponent TargetedPoint;
	
	bool bMoveCompleted = false;
	bool bInterruptBlocked = false;

	float TimeToDecelerate;

	float PeakHeightOffset;
	float InitialVelocity;
	FVector EndLocation;
	FVector StartLocation;

	/**
	 * TODO [AL]
	 * - if we are coming towards point with a more vertical then horizontal entry angle then do we want to maintain our vertical velocity and deccelerate quickly (to hit the apex / Deactivation at the same time frame as a horizontal entry)
	 * - OR do we want to deccelerate towards the end of the main grapple to point capability to have a consistent velocity from the point of this capabilitys activation?
	 * - Right now we get more of a quick stop into air jump feeling meaning we sometimes brake our velocity in the direction we want to go just to restart it
	 */

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();

		GrappleComp = UPlayerGrappleComponent::Get(Player);
		FloorMotionComp = UPlayerFloorMotionComponent::Get(Player);
		AirMotionComp = UPlayerAirMotionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (GrappleComp.Data.CurrentGrapplePoint == nullptr)
			return false;
			
		auto GrapplePoint = Cast<UGrapplePointComponent>(GrappleComp.Data.CurrentGrapplePoint);
		if (GrapplePoint == nullptr || GrappleComp.Data.GrappleState != EPlayerGrappleStates::GrappleToPoint)
			return false;

		if (!GrappleComp.Data.bGrappleToPointFinished || !GrappleComp.Data.bLedgeExit)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (bMoveCompleted)
			return true;

		if (MoveComp.HasCeilingContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.FollowComponentMovement(GrappleComp.Data.CurrentGrapplePoint, this);
		Player.SetActorVerticalVelocity(FVector::ZeroVector);

		Player.BlockCapabilities(PlayerMovementTags::FloorMotion, this);
		Player.BlockCapabilities(PlayerMovementTags::Sprint, this);

		Player.ResetAirDashUsage();
		Player.ResetAirJumpUsage();

		GrappleComp.Data.GrappleState = EPlayerGrappleStates::GrappleToPointExit;
		TargetedPoint = Cast<UGrapplePointComponent>(GrappleComp.Data.CurrentGrapplePoint);
		bMoveCompleted = false;

		Player.BlockCapabilities(BlockedWhileIn::Grapple, this);
		Player.BlockCapabilities(PlayerMovementTags::LedgeMantle, this);
		bInterruptBlocked = true;

		GrappleComp.AnimData.bGrappleToPointAirborneExit = true;

		PeakHeightOffset = GrappleComp.Settings.GrappleToPointExitHeightOffset;
		
		if(GrappleComp.GrappleToPointExitFeedbackRumble != nullptr)
			Player.PlayForceFeedback(GrappleComp.GrappleToPointExitFeedbackRumble, false, false ,this);

		// FVector HorizontalMovement = (GrappleComp.Data.GrappleToPointWorldExitLocation - GrappleComp.Data.GrappleToPointWorldTargetLocation).ConstrainToPlane(GrappleComp.Data.CurrentGrapplePoint.UpVector);
		// float Distance = HorizontalMovement.Size();

		// InitialVelocity = MoveComp.Velocity.Size();
		// float TargetSpeed = FloorMotionComp.Settings.MaximumSpeed;

		// DistanceCovered = (TargetVelocity * T) + 0.5 * T * (InitialVelocity - TargetVelocity);
		// T = (2 * DistanceCovered) / (InitialVelocity + TargetVelocity)

		// TimeToDecelerate = (2.0 * Distance) / (InitialVelocity + TargetSpeed);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Clear point for targeting by player again
		TargetedPoint.ClearPointForPlayer(Player);

		Player.UnblockCapabilities(PlayerMovementTags::LedgeMantle, this);
		Player.UnblockCapabilities(PlayerMovementTags::FloorMotion, this);
		Player.UnblockCapabilities(PlayerMovementTags::Sprint, this);

		MoveComp.UnFollowComponentMovement(this);

		if(GrappleComp.Data.GrappleState == EPlayerGrappleStates::GrappleToPointExit)
		{
			GrappleComp.Data.ResetData();
			GrappleComp.AnimData.ResetData();
		}

		// Don't allow premature canceling to overspeed
		FVector HorizontalVelocity = Player.GetActorHorizontalVelocity().GetClampedToMaxSize(AirMotionComp.Settings.HorizontalMoveSpeed);
		FVector VerticalVelocity = Player.GetActorVerticalVelocity();
		Player.SetActorVelocity(HorizontalVelocity + VerticalVelocity);

		if (bInterruptBlocked)
		{
			Player.UnblockCapabilities(BlockedWhileIn::Grapple, this);
			bInterruptBlocked = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				// const bool USE_DECELERATION = false;
				// if (USE_DECELERATION)
				// {
				// 	float Alpha = Math::Clamp(ActiveDuration / TimeToDecelerate, 0 , 1);
				// 	if (Alpha >= 1)
				// 	{
				// 		bMoveCompleted = true;
				// 	}

				// 	float TargetSpeed = FloorMotionComp.Settings.MaximumSpeed;
				// 	float DistanceCovered = (TargetSpeed * ActiveDuration) + 0.5 * (InitialVelocity - TargetSpeed) * ActiveDuration;
				// 	float Speed = Math::Lerp(InitialVelocity, TargetSpeed, Math::Saturate(ActiveDuration/TimeToDecelerate));

				// 	float HeightOffset = Math::Lerp(0, PeakHeightOffset, GrappleComp.HeightCurve.GetFloatValue(Alpha));

				// 	FVector HorizontalMovement = (GrappleComp.Data.GrappleToPointWorldExitLocation - GrappleComp.Data.GrappleToPointWorldTargetLocation).ConstrainToPlane(GrappleComp.Data.CurrentGrapplePoint.UpVector);
				// 	float TranslationAlpha = Math::Saturate(DistanceCovered / HorizontalMovement.Size());

				// 	FVector TargetLocation = Math::Lerp(GrappleComp.Data.GrappleToPointRelativeTargetLocation, GrappleComp.Data.GrappleToPointRelativeExitLocation, TranslationAlpha);
				// 	TargetLocation = GrappleComp.Data.CurrentGrapplePoint.WorldTransform.TransformPosition(TargetLocation);
				// 	TargetLocation += MoveComp.WorldUp * HeightOffset;	

				// 	FVector FrameMoveDelta = TargetLocation - Player.ActorLocation;
				// 	Movement.AddDeltaWithCustomVelocity(FrameMoveDelta, FrameMoveDelta.GetSafeNormal() * Speed);
				// }
				// else
				{
					float Alpha = Math::Clamp(ActiveDuration / GrappleComp.Settings.GrappleToPointExitDuration, 0 , 1);
					if (Alpha >= 0.45 || (Alpha >= 0.45 && MoveComp.MovementInput.Size() > 0.1))
					{
						bMoveCompleted = true;
					}

					float HeightOffset = Math::Lerp(0, PeakHeightOffset, GrappleComp.HeightOffsetCurve.GetFloatValue(Alpha));
					float TranslationAlpha = GrappleComp.GrappleToPointExitCurve.GetFloatValue(Alpha);

					FVector TargetLocation = Math::Lerp(GrappleComp.Data.GrappleToPointRelativeTargetLocation, GrappleComp.Data.GrappleToPointRelativeExitLocation, TranslationAlpha);
					TargetLocation = GrappleComp.Data.CurrentGrapplePoint.WorldTransform.TransformPosition(TargetLocation);
					TargetLocation += MoveComp.WorldUp * HeightOffset;	

					FVector FrameMoveDelta = TargetLocation - Player.ActorLocation;
					Movement.AddDelta(FrameMoveDelta);
					
					if(Alpha > 0.45)
						Movement.TraceForGroundImpact();
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Grapple");
		}

		if (bInterruptBlocked && ActiveDuration > 0.45)
		{
			Player.UnblockCapabilities(BlockedWhileIn::Grapple, this);
			bInterruptBlocked = false;
		}
	}
};