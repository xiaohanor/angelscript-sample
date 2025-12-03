class UPlayerScrambleToMantleEnterCapability : UHazePlayerCapability
{
	/* Mantle Capability which takes player up onto ledge position before transitioning into exit
	 * Data for activation is set from PlayerWallScrambleCapability
	 */

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::LedgeMantle);
	default CapabilityTags.Add(BlockedWhileIn::WallRun);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(PlayerLedgeMantleTags::LedgeMantleMovement);
	default CapabilityTags.Add(PlayerLedgeMantleTags::LedgeMantleScramble);

	default DebugCategory = n"Movement";
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 21;
	default TickGroupSubPlacement = 10;

	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;
	UPlayerLedgeMantleComponent MantleComp;
	UPlayerWallScrambleComponent ScrambleComp;

	float ActiveTimer = 0;
	float MoveAlpha = 0;
	FVector RelativeStartLocation;
	FVector RelativeEndLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();

		MantleComp = UPlayerLedgeMantleComponent::Get(Player);
		ScrambleComp = UPlayerWallScrambleComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerLedgeMantleData& ActivationParams) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (ScrambleComp.Data.State != EPlayerWallScrambleState::Scramble)
			return false;

		if(!MantleComp.Data.HasValidData())
			return false;

		// if(!ShouldMantle())
		// 	return false;
		ActivationParams = MantleComp.Data;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (MoveComp.HasImpulse())
			return true;

		if (MoveAlpha >= 1)
			return true;

		if (MantleComp.Data.TopHitComponent == nullptr || MantleComp.Data.ExitFloorHit.Component == nullptr)
			return true;

		if (MantleComp.Data.TopHitComponent.Owner.IsActorDisabled() || MantleComp.Data.ExitFloorHit.Component.Owner.IsActorDisabled())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerLedgeMantleData ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(BlockedWhileIn::LedgeMantle, this);

		// if (Player.IsMovementCameraBehaviorEnabled())
		// {

		// }

		MantleComp.Data = ActivationParams;

		if(HasControl())
		{
			ActiveTimer = 0;
			MoveAlpha = 0;

			RelativeStartLocation = MantleComp.Data.TopHitComponent.WorldTransform.InverseTransformPosition(Player.ActorLocation);
			RelativeEndLocation = MantleComp.Data.TopHitComponent.WorldTransform.InverseTransformPosition(MantleComp.Data.LedgePlayerLocation);

			FVector VerticalDelta = MantleComp.Data.LedgePlayerLocation - Player.ActorLocation;
			VerticalDelta = VerticalDelta.ConstrainToPlane(MantleComp.Data.WallHit.Normal);
		}

		ScrambleComp.StateCompleted(EPlayerWallScrambleState::Scramble);
		MantleComp.SetState(EPlayerLedgeMantleState::ScrambleEnter);
		MoveComp.FollowComponentMovement(MantleComp.Data.TopHitComponent, this);

		Player.PlayForceFeedback(MantleComp.FF_ScrambleMantle, this);

		UPlayerCoreMovementEffectHandler::Trigger_Mantle_Scramble_EnterStarted(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(BlockedWhileIn::LedgeMantle, this);
		MoveComp.UnFollowComponentMovement(this);

		MantleComp.StateCompleted(EPlayerLedgeMantleState::ScrambleEnter);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				//Translate player upwards along wall								
				ActiveTimer += DeltaTime;
				FVector StartLocation = MantleComp.Data.TopHitComponent.WorldTransform.TransformPosition(RelativeStartLocation);
				FVector EndLocation = MantleComp.Data.TopHitComponent.WorldTransform.TransformPosition(RelativeEndLocation);

				MoveAlpha = ActiveTimer / MantleComp.Settings.ScrambleEnterDuration;
				MoveAlpha = Math::Clamp(MoveAlpha, 0, 1);

				if(MoveAlpha >= 1)
				{
					MantleComp.Data.bEnterCompleted = true;

					float DurationDelta = ActiveTimer - MantleComp.Settings.ScrambleEnterDuration;
					if(DurationDelta > 0)
						MantleComp.Data.MantleDurationCarryOver = DurationDelta;
				}

				FVector TargetLocation = Math::Lerp(StartLocation, EndLocation, MoveAlpha);
				FVector FrameDelta = TargetLocation - Player.ActorLocation;

				Movement.AddDelta(FrameDelta);

				//Make sure we are rotated to face the wall we are climbing
				FQuat TargetRotation = FQuat::MakeFromXZ(-MantleComp.Data.WallHit.ImpactNormal, MoveComp.WorldUp);
				FQuat NewRotation = Math::QInterpConstantTo(Owner.ActorQuat, TargetRotation, DeltaTime, Math::DegreesToRadians(1080.0));
				Movement.SetRotation(NewRotation);

			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"LedgeMantle");
		}
	}

	bool ShouldMantle () const
	{
		float InputAngleDifference = Math::DotToDegrees(MoveComp.MovementInput.DotProduct(-MantleComp.Data.WallHit.Normal));
		if (InputAngleDifference >= 90.0)
		{
			return false;
		}

		return true;
	}
};