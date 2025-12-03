class UPlayerAirborneLedgeMantleEnterCapability : UHazePlayerCapability
{
	/*
	 * This is the AirborneRollMantle Enter capability which brings the player up to the ledge where exit will take over,
	 * Triggered when predicting a wall hit at knee height or below with primarily horizontal velocity
	 */

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::LedgeMantle);
	default CapabilityTags.Add(PlayerLedgeMantleTags::LedgeMantleMovement);
	default CapabilityTags.Add(PlayerLedgeMantleTags::LedgeMantleRoll);

	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::WallRun);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 21;
	default TickGroupSubPlacement = 10;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;

	UPlayerLedgeMantleComponent MantleComp;

	FVector RelativeStartLocation;
	FVector RelativeEndLocation;
	float ActiveTimer;
	// bool bHasBlockedCameraVolumeActivations = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();

		MantleComp = UPlayerLedgeMantleComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FAirborneRollMantleEnterActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MoveComp.IsInAir())
			return false;

		if (MantleComp.GetState() != EPlayerLedgeMantleState::Inactive)
			return false;

		if (MantleComp.Data.bEnterCompleted)
			return false;

		if (!MantleComp.Data.HasValidData())
			return false;

		if (MantleComp.TracedForState != EPlayerLedgeMantleState::AirborneRollEnter)
			return false;

		if (!ValidateEnterHeight(Params))
			return false;
		
		Params.Mantledata = MantleComp.Data;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FAirborneRollMantleEnterDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (MoveComp.HasWallContact())
			return true;

		if (MantleComp.Data.bEnterCompleted)
		{
			Params.bMoveCompleted = true;
			return true;
		}

		if (MantleComp.Data.TopHitComponent == nullptr || MantleComp.Data.ExitFloorHit.Component == nullptr)
			return true;

		if (MantleComp.Data.TopHitComponent.Owner.IsActorDisabled() || MantleComp.Data.ExitFloorHit.Component.Owner.IsActorDisabled())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FAirborneRollMantleEnterActivationParams Params)
	{
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(BlockedWhileIn::LedgeMantle, this);

		MantleComp.Data = Params.Mantledata;

		if(HasControl())
		{
			RelativeStartLocation = MantleComp.Data.TopHitComponent.WorldTransform.InverseTransformPosition(Player.ActorLocation);
			RelativeEndLocation = MantleComp.Data.TopHitComponent.WorldTransform.InverseTransformPosition(MantleComp.Data.LedgePlayerLocation);
			ActiveTimer = 0;
		}

		MantleComp.SetState(EPlayerLedgeMantleState::AirborneRollEnter);
		MoveComp.FollowComponentMovement(MantleComp.Data.TopHitComponent, this);

		// if (Player.IsMovementCameraBehaviorEnabled())
		// {
		// 	//possibly add camera impulse

		// }

		Player.PlayForceFeedback(MantleComp.FF_AirborneRollMantle, this, 0.75);

		UPlayerCoreMovementEffectHandler::Trigger_Mantle_Roll_EnterStarted(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FAirborneRollMantleEnterDeactivationParams Params)
	{
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(BlockedWhileIn::LedgeMantle, this);

		MoveComp.UnFollowComponentMovement(this);

		//Check if exit correctly took over, if not then reset
		MantleComp.StateCompleted(EPlayerLedgeMantleState::AirborneRollEnter);
	}

	bool ValidateEnterHeight(FAirborneRollMantleEnterActivationParams& ActivationParams) const
	{
		//Test to make sure we arent attempting a mantle just above walkable ground
		FHazeTraceSettings EnterLocationTest = Trace::InitFromMovementComponent(MoveComp);
		FOverlapResultArray OverlapTest = EnterLocationTest.QueryOverlaps(Player.ActorLocation + (-MoveComp.WorldUp * 20));

		if(OverlapTest.HasBlockHit())
		{
			MantleComp.Data.Reset();
			return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				ActiveTimer += DeltaTime;

				FVector StartLocation = MantleComp.Data.TopHitComponent.WorldTransform.TransformPosition(RelativeStartLocation);
				FVector EndLocation = MantleComp.Data.TopHitComponent.WorldTransform.TransformPosition(RelativeEndLocation);

				float MoveAlpha = Math::Clamp(ActiveTimer / MantleComp.Settings.AirborneRollMantleEnterDuration, 0, 1);
				
				//If we finished most of the move then just add the final distance to this frame move
				//[Al] Quick fix for small last delta move, i want to revisit this capability logic later to better maintain velocity throughout this move / make it more consistent
				if(MoveAlpha > 0.95)
					MoveAlpha = 1;

				FVector TargetLocation = Math::Lerp(StartLocation, EndLocation, MoveAlpha);
				FVector FrameDelta = TargetLocation - Player.ActorLocation;

				FRotator TargetRotation = MantleComp.Data.ExitFacingDirection.Rotation();
				FRotator NewRotation = Math::RInterpConstantTo(Player.ActorRotation, TargetRotation, DeltaTime, 540);

				if(MoveAlpha >= 1)
				{
					MantleComp.Data.bEnterCompleted = true;
				}
				
				Movement.AddDelta(FrameDelta);
				Movement.SetRotation(NewRotation);
			}
			else
				Movement.ApplyCrumbSyncedAirMovement();
				
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"LedgeMantle");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog Log)
	{
		
	}
};

struct FAirborneRollMantleEnterActivationParams
{
	FPlayerLedgeMantleData Mantledata;

	FVector RelativeStartLocation;
	FVector RelativeEndLocation;
}

struct FAirborneRollMantleEnterDeactivationParams
{
	bool bMoveCompleted = false;
}