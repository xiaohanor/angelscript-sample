class UPlayerGrappleToPointGroundedExitCapability : UHazePlayerCapability
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
	default TickGroupSubPlacement = 5;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UPlayerGrappleComponent GrappleComp;
	UPlayerFloorMotionComponent FloorMotionComp;
	UGrapplePointComponent TargetedPoint;

	bool bMoveCompleted = false;

	float DecelerationDuration = 0.09;
	float InitialSpeed = 0;

	FVector FlattenedDirection;

	/*
	 *	Grounded Grapple to point exit
	 * 	Grapple hard landing exit camera behavior
	 * 	Ground exit "Slowdown" Input "Fade in" to not get direction/rotation snapping when capability deactivates (Maybe we just do it during the exit itself)
	 * 	
	 * 
	 * When should sprint be toggled, what is our exit speed, conditional camera effects, verify deactivation conditions (Impulses/etc)
	 * 
	 */

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		GrappleComp = UPlayerGrappleComponent::Get(Player);
		FloorMotionComp = UPlayerFloorMotionComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (GrappleComp.Data.GrappleState != EPlayerGrappleStates::GrappleToPointGrounded)
			return false;

		if (GrappleComp.Data.CurrentGrapplePoint == nullptr)
			return false;

		auto GrapplePoint = Cast<UGrapplePointComponent>(GrappleComp.Data.CurrentGrapplePoint);
		if (GrapplePoint == nullptr)
			return false;

		if (!GrappleComp.Data.bGrappleToPointFinished || GrappleComp.Data.bLedgeExit)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (MoveComp.HasWallContact())
			return true;

		if (MoveComp.HasUpwardsImpulse())
			return true;

		if (MoveComp.IsInAir())
			return true;

		if (bMoveCompleted)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GrappleComp.Data.GrappleState = EPlayerGrappleStates::GrappleToPointGroundedExit;
		TargetedPoint = Cast<UGrapplePointComponent>(GrappleComp.Data.CurrentGrapplePoint);

		InitialSpeed = MoveComp.Velocity.Size();

		if(MoveComp.HorizontalVelocity.Size() < KINDA_SMALL_NUMBER)
			FlattenedDirection = Player.ActorForwardVector;
		else
			FlattenedDirection = MoveComp.GetHorizontalVelocity().GetSafeNormal();

		bMoveCompleted = false;

		if(GrappleComp.GrappleToPointGroundExitRumble != nullptr)
			Player.PlayForceFeedback(GrappleComp.GrappleToPointGroundExitRumble, false, false, this);
		
		UPlayerCoreMovementEffectHandler::Trigger_Grapple_GroundedExit(Player);
		FHazeCameraImpulse GroundImpactImpulse;
		GroundImpactImpulse.WorldSpaceImpulse = MoveComp.GravityDirection * 1750;
		GroundImpactImpulse.ExpirationForce = 80;
		GroundImpactImpulse.Dampening = 1;
		Player.ApplyCameraImpulse(GroundImpactImpulse, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TargetedPoint.ClearPointForPlayer(Player);

		GrappleComp.Data.ResetData();	
		GrappleComp.AnimData.ResetData();

		if(!bMoveCompleted)
		{
			if(MoveComp.IsInAir())
				Player.SetActorHorizontalVelocity(MoveComp.HorizontalVelocity.GetSafeNormal() * (UPlayerAirMotionComponent::Get(Player).Settings.HorizontalMoveSpeed + 250));
			else
				Player.SetActorHorizontalVelocity(MoveComp.HorizontalVelocity.GetSafeNormal() * FloorMotionComp.Settings.MaximumSpeed);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//Here we could lerp in control over the duration to not get a snap when finishing (do we maybe want to increase the duration of the exit a abit and/or allow jump cancelling?)
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				float Alpha = Math::GetMappedRangeValueClamped(FVector2D(0, DecelerationDuration), FVector2D(0, 1), ActiveDuration);
				
				float CurvedAlpha = GrappleComp.ExitDecelerationCurve.GetFloatValue(Alpha);

				float TargetSpeed;

				if(InitialSpeed > GrappleComp.Settings.GrappleToPointGroundedExitSpeed)
				{
					//This curve goes from 1 to 0 cause that made sense as a decceleration curve in my head ¯\_(ツ)_/¯
					TargetSpeed = Math::Lerp(GrappleComp.Settings.GrappleToPointGroundedExitSpeed, InitialSpeed,  CurvedAlpha);
				}
				else
					TargetSpeed = InitialSpeed;

				Movement.AddHorizontalVelocity(FlattenedDirection * TargetSpeed);
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.OverrideStepUpAmountForThisFrame(50);
				Movement.SetRotation(MoveComp.GetRotationBasedOnVelocity());

				//Trying out conditional edge stop
				if(MoveComp.MovementInput.DotProduct(MoveComp.HorizontalVelocity.GetSafeNormal()) < 0.75)
					Movement.StopMovementWhenLeavingEdgeThisFrame();
				
				if(Alpha >= 1)
					bMoveCompleted = true;
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Grapple");
		}
	}
};