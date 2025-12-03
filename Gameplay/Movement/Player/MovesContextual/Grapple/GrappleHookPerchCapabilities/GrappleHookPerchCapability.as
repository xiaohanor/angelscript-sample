struct FGrappleToPerchActivationParams
{
	FPlayerGrappleData Data;
};

struct FGrappleToPerchDeactivationParams
{
	bool bMoveFinished = false;
	bool bAllowPerch = false;
	bool bCollided = false;
}

class UPlayerGrappleHookPerchCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Grapple);
	default CapabilityTags.Add(PlayerGrappleTags::GrapplePerch);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleMovement);
	default CapabilityTags.Add(PlayerMovementTags::Perch);

	default BlockExclusionTags.Add(PlayerMovementExclusionTags::ExcludeGrapple);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 4;
	default TickGroupSubPlacement = 8;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerGrappleComponent GrappleComp;
	UPlayerPerchComponent PerchComp;
	UPerchPointComponent PerchPoint;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	FVector TargetLocation;
	FVector RelativeTargetLocation;
	FVector StartLocation;
	FVector RelativeStartLocation;
	FVector JumpStartLocation;
	bool bShouldApplyCameraImpulse = false;

	bool bHasReachedTarget = false;
	bool bInsideQuickGrappleRange = false;

	/*
	 * TODO (AL):
	 * Should we let go / enter perch with some velocity if we enter aligned with the spline direction?
	 */

	//
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		GrappleComp = UPlayerGrappleComponent::GetOrCreate(Player);
		PerchComp = UPlayerPerchComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGrappleToPerchActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (GrappleComp.Data.CurrentGrapplePoint == nullptr)
			return false;

		if (!GrappleComp.Data.bEnterFinished || GrappleComp.Data.CurrentGrapplePoint.GrappleType != EGrapplePointVariations::PerchPoint)
			return false;
		
		Params.Data = GrappleComp.Data;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGrappleToPerchDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
		{
			Params.bMoveFinished = bHasReachedTarget;
			return true;
		}

		if (MoveComp.HasCeilingContact() || MoveComp.HasWallContact())
		{
			Params.bCollided = true;
			return true;
		}

		if (bHasReachedTarget)
		{
			Params.bAllowPerch = PerchPoint != nullptr && PerchPoint.bAllowPerch;
			Params.bMoveFinished = true;
			return true;
		}

		if (GrappleComp.Data.CurrentGrapplePoint.IsDisabledForPlayer(Player))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGrappleToPerchActivationParams Params)
	{
		Player.BlockCapabilities(BlockedWhileIn::Grapple, this);
		GrappleComp.Data = Params.Data;

		PerchPoint = Cast<UPerchPointComponent>(GrappleComp.Data.CurrentGrapplePoint);
		MoveComp.FollowComponentMovement(PerchPoint, this, EMovementFollowComponentType::Teleport);
		PerchComp.Data.TargetedPerchPoint = PerchPoint;

		bHasReachedTarget = false;

		//Transform and assign our initial target/Start locations to relative for later converting to world to support moving targets
		if (PerchPoint.bHasConnectedSpline)
		{
			RelativeTargetLocation = GrappleComp.Data.GrappleToPointRelativeTargetLocation;
			TargetLocation = GrappleComp.Data.GrappleToPointWorldTargetLocation;

			RelativeStartLocation = PerchPoint.ConnectedSpline.Spline.WorldTransform.InverseTransformPosition(Player.ActorLocation);
			StartLocation = PerchPoint.ConnectedSpline.Spline.WorldTransform.TransformPosition(RelativeStartLocation);
		}
		else
		{
			RelativeTargetLocation = GrappleComp.Data.GrappleToPointRelativeTargetLocation;
			TargetLocation = GrappleComp.Data.GetGrappleToPointWorldTargetLocation();

			RelativeStartLocation = PerchPoint.WorldTransform.InverseTransformPosition(Player.ActorLocation);
			StartLocation = PerchPoint.WorldTransform.TransformPosition(RelativeStartLocation);
		}

		if (PerspectiveModeComp.IsCameraBehaviorEnabled() && !PerchPoint.bBlockCameraEffectsForPoint)
			HandleCameraOnActivation();
		else
			bShouldApplyCameraImpulse = false;


		//Assign State Data
		GrappleComp.Data.GrappleState = EPlayerGrappleStates::GrapplePerch;

		float ToPointDelta = (GrappleComp.Data.GetGrappleToPointWorldTargetLocation() - Player.ActorLocation).Size();
		if (!GrappleComp.Data.bPerformPerchExit && ToPointDelta <= GrappleComp.Settings.TriggerLandingDistance)
		{
			bInsideQuickGrappleRange = true;
			GrappleComp.AnimData.bPerformQuickPerchGrapple = true;
		}
		else
			bInsideQuickGrappleRange = false;

		Player.BlockCapabilities(PlayerPerchPointTags::PerchPointLand, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGrappleToPerchDeactivationParams Params)
	{
		Player.UnblockCapabilities(BlockedWhileIn::Grapple, this);
		Player.UnblockCapabilities(PlayerPerchPointTags::PerchPointLand, this);
		MoveComp.UnFollowComponentMovement(this);	

		if(Params.bMoveFinished)
		{
			GrappleComp.Grapple.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
			GrappleComp.Grapple.SetActorHiddenInGame(true);

			if(GrappleComp.Data.GrappleState == EPlayerGrappleStates::GrapplePerchExit)
			{
				//Our airborne perch exit capability took over

			}
			else
			{
				//We are not performing our ToPerchExit move so check for valid perch
				if(Params.bAllowPerch)
				{
					PerchComp.StartPerching(PerchComp.Data.TargetedPerchPoint, true);
					Player.SetActorVelocity(FVector::ZeroVector);
				}
				else
				{
					PerchComp.SetState(EPlayerPerchState::Inactive);
					PerchComp.Data.TargetedPerchPoint = nullptr;

					FVector MoveInput = MoveComp.MovementInput;
					MoveComp.OverridePreviousGroundContactWithCurrent();
					Player.SetActorVelocity(MoveInput.GetSafeNormal() * 550.0);
				}

				if (IsValid(PerchPoint))
					PerchPoint.OnPlayerFinishedGrapplingToPointEvent.Broadcast(Player, PerchPoint);

				//Reset Component Data
				GrappleComp.Data.ResetData();
				GrappleComp.AnimData.ResetData();
			}
		}
		else
		{
			// The grapple was interrupted
			if(IsValid(PerchPoint))
				PerchPoint.OnPlayerInterruptedGrapplingToPointEvent.Broadcast(Player, PerchPoint);

			//We didnt finish the move, either another grapple was initiated or we deactivated due to other reasons
			if(GrappleComp.Data.GrappleState == EPlayerGrappleStates::GrapplePerch)
			{
				//Nothing took over / no new grapple was initiated
				GrappleComp.Grapple.AttachToActor(Player, n"LeftAttach", EAttachmentRule::SnapToTarget);
				GrappleComp.Grapple.SetActorHiddenInGame(true);

				if(Params.bCollided)
				{
					Player.SetActorVelocity(FVector::ZeroVector);
				}

				GrappleComp.Data.ResetData();
				GrappleComp.AnimData.ResetData();
			}
			else
			{
				//Either another grapple was initiated or something like a death reset our operational data so just clean up anything that could affect a new grapple
				GrappleComp.AnimData.bPerchGrappling = false;
			}
		}

		// //Clear the point from being activated by player, enabling polling from as targetable
		if (IsValid(PerchPoint))
		{
			PerchPoint.ClearPointForPlayer(Player);
			PerchPoint = nullptr;
		}

		Player.ClearCameraSettingsByInstigator(this, 2.5);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bShouldApplyCameraImpulse && (ActiveDuration / GrappleComp.Settings.GrappleDuration) >= 0.925)
		{
			FHazeCameraImpulse CamImpulse;
			CamImpulse.AngularImpulse = FRotator(-25.0, 0.0, 0.0);
			CamImpulse.WorldSpaceImpulse = FVector(0.0, 0.0, -450.0);
			CamImpulse.ExpirationForce = 35;
			CamImpulse.Dampening = 0.8;
			Player.ApplyCameraImpulse(CamImpulse, this);
			bShouldApplyCameraImpulse = false;
		}

		//Transform relative locations from activation to world locations to accommodate moving targets
		FVector FinalLocation;
		if (PerchPoint.bHasConnectedSpline)
		{
			FinalLocation = GrappleComp.Data.GrappleToPointWorldTargetLocation;
			TargetLocation = FinalLocation;
			StartLocation = PerchPoint.ConnectedSpline.Spline.WorldTransform.TransformPosition(RelativeStartLocation);
		}
		else
		{
			TargetLocation = GrappleComp.Data.GetGrappleToPointWorldTargetLocation();
			StartLocation = PerchPoint.WorldTransform.TransformPosition(RelativeStartLocation);
		}

		if(HasControl())
		{		
			if(MoveComp.PrepareMove(Movement))
			{
				float Speed = Math::Lerp(0, GrappleComp.Settings.GrappleToPointTopVelocity, GrappleComp.AccelerationCurve.GetFloatValue(ActiveDuration / GrappleComp.Settings.GrappleToPointAccelerationDuration));

				FVector Direction = TargetLocation - Player.ActorLocation;
				Direction = Direction.GetSafeNormal();

				FVector FrameDeltaMove = Direction * Speed * DeltaTime;
				float ToPointDelta = (GrappleComp.Data.GetGrappleToPointWorldTargetLocation() - Player.ActorLocation).Size();
				
				if(!bInsideQuickGrappleRange && !GrappleComp.Data.bPerformPerchExit && ToPointDelta <= GrappleComp.Settings.TriggerLandingDistance)
				{
					GrappleComp.AnimData.bAnticipatePerchLanding = true;
				}

				if(FrameDeltaMove.Size() >= ToPointDelta)
				{
					FrameDeltaMove = FrameDeltaMove.GetSafeNormal() * ToPointDelta;
					bHasReachedTarget = true;
					GrappleComp.Data.bGrappleToPointFinished = true;
				}

				Movement.SetRotation(Direction.Rotation());
				Movement.AddDelta(FrameDeltaMove);
				MoveComp.ApplyMove(Movement);
			}
		}
		else
		{
			if (MoveComp.PrepareMove(Movement))
			{
				Movement.ApplyCrumbSyncedAirMovement();
				MoveComp.ApplyMove(Movement);
			}
		}

		Player.Mesh.RequestLocomotion(n"Grapple", this);
		GrappleComp.RetractGrapple(ActiveDuration);
	}

	void HandleCameraOnActivation()
	{
		bShouldApplyCameraImpulse = true;
		
		Player.ApplyCameraSettings(GrappleComp.GrappleCamSetting, 1.35, this, SubPriority = 51);
		Player.PlayCameraShake(GrappleComp.GrappleShake, this, 2.0);

		// UCameraPointOfInterest PoI = Player.CreatePointOfInterest();
		// PoI.FocusTarget.SetFocusToComponent(GrappleComp.Data.CurrentGrapplePoint);

		// FVector PlayerToPoint = GrappleComp.Data.CurrentGrapplePoint.Owner.ActorLocation - Player.ActorLocation;
		// PlayerToPoint = PlayerToPoint.ConstrainToPlane(MoveComp.WorldUp);
		// PlayerToPoint = PlayerToPoint.GetSafeNormal();

		// PoI.FocusTarget.WorldOffset = (PlayerToPoint * 1000) + FVector(0, 0, -250);

		// PoI.Settings.ClearOnInput = CameraPOIDefaultClearOnInput;
		// PoI.Settings.RegainInputTime = 0.2;

		// PoI.Settings.Duration = GrappleComp.Settings.GrappleDuration - 0.65;
		// PoI.Apply(this, 0.65);
	}
};

