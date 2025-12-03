class UPlayerPoleClimbJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::PoleClimb);
	default CapabilityTags.Add(PlayerPoleClimbTags::PoleClimbJumpOut);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 24;
	default TickGroupSubPlacement = 2;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerPoleClimbComponent PoleClimbComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;
	
	APoleClimbActor CurrentPole;

	//Sign for if we are climbing along the poles upvector or not since poles are multidirectional
	int PoleUpSign = 1;
	float SignedAngle = 0;
	float ExitTimer = 0;
	float CurrentHeight = 0;
	FVector TargetLocation;
	FVector StartLocation;

	bool bIsMovementInputLocked = false;
	float InputLockedTimer = 0.0;
	FVector WantedJumpDirection;
	FVector2D LockedStickDirection;
	FRotator InitialRotation;

	bool bFinishedAnticipation = false;
	bool bInitiatedOffsetFreeze = false;
	bool bCalculatedRotation = false;

	bool bHasTargetTransfer;
	FVector TargetTransferPoint;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		PoleClimbComp = UPlayerPoleClimbComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (!WasActionStarted(ActionNames::MovementJump) && !PoleClimbComp.Data.bJumpOffBuffered)
			return false;

		if (PoleClimbComp.GetState() != EPlayerPoleClimbState::Climbing && PoleClimbComp.GetState() != EPlayerPoleClimbState::Enter)
			return false;

		if (PoleClimb::bEnable2DPoleClimb)
		{
			if (!PerspectiveModeComp.IsIn3DPerspective())
				return false;
		}

		if (PoleClimbComp.Data.bPerformingTurnaround && !PoleClimb::bJumpOffInInputDirection)
		{
			FVector DirToPlayer = PoleClimbComp.GetPoleToPlayerVector();
			FVector ClosestAllowedDir = PoleClimbComp.GetClosestPoleAllowedDirection(DirToPlayer);

			// If we are very far away from an allowed direction, don't allow the jump just now,
			// the turnaround's jump buffering will make it trigger as soon as we're close enough to the direction
			// we will actually jump off.
			if (DirToPlayer.GetAngleDegreesTo(ClosestAllowedDir) > 45.0)
				return false;

			// If we are inputting in the opposite direction of what our jumpoff would be, don't allow it now
			// This is here so if you're holding a direction to do a turnaround, and then immediately jump, we don't
			// end up jumping in the complete opposite direction because the jumpoff triggers while the turnaround hasn't
			// done much yet.
			if (MoveComp.MovementInput.Size() > 0.1 && MoveComp.MovementInput.GetAngleDegreesTo(ClosestAllowedDir) > 100.0)
				return false;
		}

		return true;
	}

	bool bHasLaunchedPlayer = false;

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bHasLaunchedPlayer)
			return true;
			
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// If we've just done a transfer-assist, we temporarily lock input in that direction,
		// until either we significantly change the stick direction or it times out.
		if (bIsMovementInputLocked)
		{
			InputLockedTimer += DeltaTime;

			FVector2D CurrentInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			if (InputLockedTimer > 1.0 || LockedStickDirection.Distance(CurrentInput) > 0.25 || !MoveComp.IsInAir() || PoleClimbComp.IsClimbing())
			{
				bIsMovementInputLocked = false;
				Player.ClearMovementInput(this);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);

		CurrentPole = PoleClimbComp.Data.ActivePole;

		MoveComp.FollowComponentMovement(CurrentPole.RootComp, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);

		Player.BlockCapabilities(PlayerMovementTags::Perch, this);

		PoleClimbComp.Data.bJumpOffBuffered = false;

		CurrentHeight = PoleClimbComp.Data.CurrentHeight;
		PoleUpSign = PoleClimbComp.Data.ClimbDirectionSign;

		if (PoleClimb::bJumpOffInInputDirection && MoveComp.MovementInput.Size() > 0.1)
			WantedJumpDirection = MoveComp.MovementInput;
		else if (PoleClimbComp.Data.bPerformingTurnaround)
			WantedJumpDirection = PoleClimbComp.Data.TurnAroundTargetPoleToPlayer;
		else
			WantedJumpDirection = Player.ActorLocation - (CurrentPole.ActorLocation + (CurrentPole.ActorUpVector * PoleClimbComp.Data.CurrentHeight));

		WantedJumpDirection = WantedJumpDirection.ConstrainToPlane(MoveComp.WorldUp);
		WantedJumpDirection = WantedJumpDirection.GetSafeNormal();

		InitialRotation = Player.ActorRotation;

		if (!CurrentPole.bAllowFull360Rotation)
			WantedJumpDirection = PoleClimbComp.GetClosestPoleAllowedDirection(WantedJumpDirection);

		bHasTargetTransfer = false;

		// If we found a pole to auto-aim to, bend the input
		auto BestPole = PoleClimbComp.GetPoleClimbTransferAssistTarget(WantedJumpDirection, MoveComp.MovementInput);
		if (BestPole != nullptr)
		{
			TargetTransferPoint = Math::ClosestPointOnInfiniteLine(
				BestPole.ActorLocation, BestPole.ActorLocation + BestPole.ActorUpVector,
				Player.ActorLocation
			);
			WantedJumpDirection = (TargetTransferPoint - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

			bIsMovementInputLocked = true;
			bHasTargetTransfer = true;
			InputLockedTimer = 0.0;
			LockedStickDirection = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

			Player.ApplyMovementInput(WantedJumpDirection, this, EInstigatePriority::High);
		}

		if(PoleClimbComp.Data.ActivePole != nullptr)
		{
			if(PoleClimbComp.GetState() == EPlayerPoleClimbState::Enter)
				PoleClimbComp.Data.ActivePole.OnEnterFinished.Broadcast(Player, PoleClimbComp.Data.ActivePole);
		}

		//Detach from pole and clean up previous data
		PoleClimbComp.StopClimbing();
		PoleClimbComp.ResetCooldown();

		PoleClimbComp.AnimData.bJumping = true;
		PoleClimbComp.SetState(EPlayerPoleClimbState::JumpOut);

		UPlayerCoreMovementEffectHandler::Trigger_Pole_JumpOut(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);
		Player.UnblockCapabilities(PlayerMovementTags::Perch, this);
		MoveComp.UnFollowComponentMovement(this);

		CurrentPole.OnJumpOff.Broadcast(Player, CurrentPole, WantedJumpDirection);

		PoleClimbComp.AnimData.bJumping = false;
		PoleClimbComp.SetState(EPlayerPoleClimbState::Inactive);
		CurrentPole = nullptr;
		bFinishedAnticipation = false;
		bCalculatedRotation = false;
		bHasLaunchedPlayer = false;
		bInitiatedOffsetFreeze = false;
		ExitTimer = 0;
		SignedAngle = 0;

		PoleClimbComp.AnimData.JumpOutAngle = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			ExitTimer += DeltaTime;

			if(HasControl())
			{	
				FVector Velocity = FVector::ZeroVector;
				FRotator JumpOutRotation;

				if(!bFinishedAnticipation)
				{
					if(ExitTimer >= PoleClimbComp.Settings.JumpOutAnticipationTime)
					{	
						bFinishedAnticipation = true;
						Player.PlayForceFeedback(PoleClimbComp.JumpOutFF, false, false, this);
					}
				}
				else
				{
					Velocity = WantedJumpDirection * PoleClimbComp.Settings.JumpOutHorizontalImpulse;

					float VerticalImpulse = PoleClimbComp.Settings.JumpOutVerticalImpulse;
					if (bHasTargetTransfer)
					{
						float HorizDistance = TargetTransferPoint.Dist2D(Player.ActorLocation, MoveComp.WorldUp);
						float HorizTime = HorizDistance / PoleClimbComp.Settings.JumpOutHorizontalImpulse;

						VerticalImpulse = Math::Min(
							VerticalImpulse,
							Math::Max(Trajectory::GetSpeedToReachTarget(-50.0, HorizTime, -MoveComp.GravityForce), 0.0),
						);
					}

					Velocity += Player.MovementWorldUp * VerticalImpulse;
					bHasLaunchedPlayer = true;
					ApplyCameraImpulse();
				}
	
				JumpOutRotation = Velocity.ConstrainToPlane(Player.MovementWorldUp).Rotation();
				JumpOutRotation = FRotator::MakeFromXZ(JumpOutRotation.ForwardVector, MoveComp.WorldUp);

				FVector PlayerToPole = (CurrentPole.ActorLocation + (CurrentPole.ActorUpVector * CurrentHeight)) - Player.ActorLocation;
				PlayerToPole = PlayerToPole.ConstrainToPlane(MoveComp.WorldUp);
				PlayerToPole = PlayerToPole.GetSafeNormal();
				
				//Calculate Angle
				float Angle = PlayerToPole.GetAngleDegreesTo(WantedJumpDirection.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal());

				//Calculate Signed Angle
				if(!bCalculatedRotation)
				{
					float Sign = Math::Sign(Player.ActorRightVector.DotProduct(WantedJumpDirection.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal()));
					SignedAngle = Angle * (Sign > 0 ?  1 : -1);
					bCalculatedRotation = true;

					float JumpDirectionDot = WantedJumpDirection.DotProduct(Player.ActorRightVector);
					PoleClimbComp.AnimData.bJumpingTowardsRight = JumpDirectionDot >= 0 ? true : false;
				
					PoleClimbComp.AnimData.JumpOutAngle = SignedAngle;
				}
				
				//Calculate our rotation to hold during anticipation (Capsule will snap to align with the jumpout duration so we have to counter it a bit during anticipation)
				FRotator AnticipationTargetRotation;
				if(SignedAngle >= 45 && SignedAngle <= 135)
				{
					AnticipationTargetRotation = FRotator::MakeFromXZ(-PlayerToPole.CrossProduct(CurrentPole.ActorUpVector * PoleUpSign), CurrentPole.ActorUpVector * PoleUpSign);
				}
				else if (SignedAngle <= -45 && SignedAngle > -135)
				{
					AnticipationTargetRotation = FRotator::MakeFromXZ(PlayerToPole.CrossProduct(CurrentPole.ActorUpVector * PoleUpSign) , CurrentPole.ActorUpVector * PoleUpSign);
				}
				else if(SignedAngle >= -45 && SignedAngle <= 45)
				{
					AnticipationTargetRotation = FRotator::MakeFromXZ(PlayerToPole.ConstrainToPlane(CurrentPole.ActorUpVector).GetSafeNormal(), CurrentPole.ActorUpVector * PoleUpSign);
				}
				else
				{
					AnticipationTargetRotation = FRotator::MakeFromXZ(-PlayerToPole.ConstrainToPlane(CurrentPole.ActorUpVector).GetSafeNormal(), CurrentPole.ActorUpVector * PoleUpSign);
				}

				FRotator TargetDirection = (bHasLaunchedPlayer ? JumpOutRotation : AnticipationTargetRotation);

				Movement.AddVelocity(Velocity);
				Movement.SetRotation(TargetDirection);
				Movement.OverrideStepDownAmountForThisFrame(0.0);
				Movement.IgnoreSplineLockConstraint();

				if(bHasLaunchedPlayer && !bInitiatedOffsetFreeze)
				{
					MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);
					MoveComp.UnFollowComponentMovement(this);
					Player.RootOffsetComponent.FreezeRotationAndLerpBackToParent(n"PoleResetRotation", 0.2);
					Player.RootOffsetComponent.FreezeLocationAndLerpBackToParent(n"PoleResetLocation", 0.1);
					bInitiatedOffsetFreeze = true;
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			
			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"PoleClimb", this);
		}
	}

	void ApplyCameraImpulse()
	{
		if (PerspectiveModeComp.IsCameraBehaviorEnabled()
			&& CurrentPole.JumpCameraImpulseStrength != 0.0
			&& Player.ViewRotation.ForwardVector.DotProduct(WantedJumpDirection) > 0.5
		)
		{
			FHazeCameraImpulse CamImpulse;
			CamImpulse.CameraSpaceImpulse = FVector(0, CurrentPole.JumpCameraImpulseStrength, 0);
			if (Player.ViewRotation.RightVector.DotProduct(WantedJumpDirection) < -0.2)
			{
				CamImpulse.CameraSpaceImpulse *= -1.0;
			}

			CamImpulse.Dampening = 0.8;
			CamImpulse.ExpirationForce = 5.0;
			Player.ApplyCameraImpulse(CamImpulse, this);
		}
	}
};

