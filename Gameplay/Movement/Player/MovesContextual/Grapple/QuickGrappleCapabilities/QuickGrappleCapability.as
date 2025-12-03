
class UPlayerQuickGrappleCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Grapple);
	default CapabilityTags.Add(PlayerGrappleTags::QuickGrapple);

	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::LedgeGrab);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::WallScramble);
	default CapabilityTags.Add(BlockedWhileIn::WallRun);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludeGrapple);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 5;
	default TickGroupSubPlacement = 1;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerGrappleComponent GrappleComp;
	UPlayerTargetablesComponent TargetablesComp;
	UPlayerPerchComponent PerchComp;

	float MoveDuration = .6;

	FVector StartLocation;
	FVector TargetLocation;

	UPerchPointComponent PerchPoint;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		GrappleComp = UPlayerGrappleComponent::GetOrCreate(Player);
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);
		PerchComp = UPlayerPerchComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FQuickGrappleEnterActivationParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;
		
		if(GrappleComp.Data.GrappleState != EPlayerGrappleStates::QuickGrapplePerch)
			return false;
		
		if(GrappleComp.Data.CurrentGrapplePoint == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FQuickGrappleDeactivationParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(ActiveDuration >= MoveDuration)
		{
			Params.bMoveCompleted = true;

			auto CurrentPerchPoint = Cast<UPerchPointComponent>(GrappleComp.Data.CurrentGrapplePoint);
			Params.bPerchOnPoint = PerchPoint != nullptr && CurrentPerchPoint.bAllowPerch;

			return true;
		}

		if (GrappleComp.Data.CurrentGrapplePoint.IsDisabledForPlayer(Player))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FQuickGrappleEnterActivationParams Params)
	{
		Player.BlockCapabilities(BlockedWhileIn::Grapple, this);

		StartLocation = Player.ActorLocation;
		TargetLocation = GrappleComp.Data.CurrentGrapplePoint.WorldLocation;

		GrappleComp.CalculateHeightOffset();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FQuickGrappleDeactivationParams Params)
	{
		Player.UnblockCapabilities(BlockedWhileIn::Grapple, this);

		//Make sure we are in the same state as when started (nothing interrupted) and cleanup / reset)
		if (GrappleComp.Data.GrappleState == EPlayerGrappleStates::QuickGrapplePerch)
		{
			GrappleComp.Grapple.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
			GrappleComp.Grapple.SetActorHiddenInGame(true);

			GrappleComp.Data.GrappleState = EPlayerGrappleStates::Inactive;
		}

		if(Params.bMoveCompleted)
		{
			PerchPoint = Cast<UPerchPointComponent>(GrappleComp.Data.CurrentGrapplePoint);
			PerchComp.Data.TargetedPerchPoint = PerchPoint;

			if (IsValid(PerchPoint))
				PerchPoint.OnPlayerFinishedGrapplingToPointEvent.Broadcast(Player, GrappleComp.Data.CurrentGrapplePoint);

			if(PerchPoint != nullptr && Params.bPerchOnPoint)
			{
				if(PerchPoint.bHasConnectedSpline)
					PerchComp.Data.State = EPlayerPerchState::PerchingOnSpline;
				else
					PerchComp.Data.State = EPlayerPerchState::PerchingOnPoint;
			}
			else
			{
				PerchComp.Data.State = EPlayerPerchState::Inactive;
				PerchComp.Data.TargetedPerchPoint = nullptr;

				FVector MoveInput = MoveComp.MovementInput;
				MoveComp.OverridePreviousGroundContactWithCurrent();
				Player.SetActorVelocity(MoveInput.GetSafeNormal() * 550.0);
			}
		}
		else
		{
			// Move did not complete
			if (IsValid(PerchPoint))
				PerchPoint.OnPlayerInterruptedGrapplingToPointEvent.Broadcast(Player, GrappleComp.Data.CurrentGrapplePoint);
		}

		if (IsValid(PerchPoint))
			PerchPoint.ClearPointForPlayer(Player);

		PerchPoint = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				TargetLocation = GrappleComp.Data.CurrentGrapplePoint.WorldLocation;
				float Alpha = ActiveDuration / MoveDuration;
				float CurvedAlpha = GrappleComp.SpeedCurve.GetFloatValue(Alpha);

				FVector NewLoc = Math::Lerp(StartLocation, TargetLocation, CurvedAlpha);
				FVector HeightOffset = MoveComp.WorldUp * GrappleComp.HeightCurve.GetFloatValue(Alpha) * (GrappleComp.GrappleHeightOffset / 2);
				NewLoc += HeightOffset;

				FVector DeltaMove = NewLoc - Player.ActorLocation;						

				/*
				 * Turn towards point, Activate poi and do a quick Grapple throw towards point (Enter)
				 * Once attached start accelerating the velocity towards the point OR do a quick Snap/Tug of the grapple and launch arcing above the point onto it like current grapple
				 * Key part is no decceleration/air braking like current long range grapple.
				 */

				Movement.AddDelta(DeltaMove);
				Movement.SetRotation((GrappleComp.Data.CurrentGrapplePoint.WorldLocation - Player.ActorLocation).GetSafeNormal().Rotation());
				Movement.OverrideStepDownAmountForThisFrame(0.0);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"QuickGrapple");

		float Alpha = ActiveDuration / MoveDuration;

		FVector NewLoc = Math::Lerp(GrappleComp.Data.CurrentGrapplePoint.WorldLocation, Player.Mesh.GetSocketLocation(n"LeftAttach"), Alpha);
		GrappleComp.Grapple.SetActorLocation(NewLoc);
		float NewTense = Math::Lerp(0.15, 2.15, Alpha);
		GrappleComp.Grapple.Tense = NewTense;
		}
	}
}

struct FQuickGrappleDeactivationParams
{
	bool bMoveCompleted = false;
	bool bPerchOnPoint = false;
}