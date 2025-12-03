class UPlayerGrappleToPointHardLandingCapability : UHazePlayerCapability
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
	default TickGroupOrder = 48;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 4, 4);

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UPlayerGrappleComponent GrappleComp;
	UPlayerFloorMotionComponent FloorMotionComp;
	UGrapplePointComponent TargetedPoint;

	bool bMoveCompleted = false;

	float LandingDuration = 1;

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

		if (GrappleComp.Data.VerticalAngleDelta > -75)
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

		if (bMoveCompleted)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(PlayerMovementTags::Jump, this);

		TargetedPoint = Cast<UGrapplePointComponent>(GrappleComp.Data.CurrentGrapplePoint);
		bMoveCompleted = false;

		/*Temp Animation stuff */
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = GrappleComp.HardLandingAnim;
		AnimParams.bLoop = false;
		AnimParams.BlendTime = 0.1;

		Player.PlaySlotAnimation(AnimParams);

		TargetedPoint.ClearPointForPlayer(Player);

		GrappleComp.Data.ResetData();
		GrappleComp.AnimData.ResetData();

		//here we probably want a short shake instead
		FHazeCameraImpulse GroundImpactImpulse;
		GroundImpactImpulse.WorldSpaceImpulse = MoveComp.GravityDirection * 1500;
		GroundImpactImpulse.ExpirationForce = 400;
		GroundImpactImpulse.Dampening = 75;
		Player.ApplyCameraImpulse(GroundImpactImpulse, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
		Player.StopAllSlotAnimations(0.1);

		TargetedPoint = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				if(ActiveDuration >= LandingDuration)
					bMoveCompleted = true;

			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Movement");
		}
	}
};