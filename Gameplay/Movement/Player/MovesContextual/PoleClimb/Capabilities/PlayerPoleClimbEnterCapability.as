class UPlayerPoleClimbEnterCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::PoleClimb);
	default CapabilityTags.Add(PlayerPoleClimbTags::PoleClimbEnter);

	default CapabilityTags.Add(BlockedWhileIn::Ladder);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 24;
	default TickGroupSubPlacement = 3;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	bool bEnterFinished;

	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;
	UPlayerPoleClimbComponent PoleClimbComp;
	UPlayerPerchComponent PerchComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	FVector PoleRelativeTargetLocation;
	FVector PoleRelativeStartLocation;
	FRotator StartRot;
	FRotator TargetRot;

	float TurnAroundStartAngle;
	float TurnAroundTargetAngle;
	bool bTurnAroundClockwise;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupTeleportingMovementData();
		PoleClimbComp = UPlayerPoleClimbComponent::GetOrCreate(Player);
		PerchComp = UPlayerPerchComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerPoleClimbEnterActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if(PoleClimbComp.OverlappingPoles.Num() == 0)
			return false;

		if (PoleClimbComp.GetState() != EPlayerPoleClimbState::Inactive)
			return false;

		if (PoleClimbComp.OnCooldown())
			return false;

		FPoleClimbEnterTestData TestData;
		if (!PoleClimbComp.TestForValidEnter(TestData))
			return false;
		
		Params.TestData = TestData;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPlayerPoleClimbEnterDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (PoleClimbComp.Data.ActivePole == nullptr)
			return true;

		if (PoleClimbComp.Data.ActivePole.IsActorDisabled() || PoleClimbComp.Data.ActivePole.IsPoleDisabled())
			return true;

		if (PoleClimbComp.Data.State != EPlayerPoleClimbState::Enter)
			return true;

		if (bEnterFinished)
		{
			Params.bMoveFinished = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerPoleClimbEnterActivationParams Params)
	{
		Player.BlockCapabilities(BlockedWhileIn::PoleClimb, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);

		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);

		PoleClimbComp.Data.VelocityOnEnter = MoveComp.Velocity;
		PoleClimbComp.StartClimbing(Params.TestData);
		PoleClimbComp.AnimData.bInEnter = true;
		PoleClimbComp.SetState(EPlayerPoleClimbState::Enter);

		bEnterFinished = false;

		//Calculate Character rotation as well as Start/endLocation for move transition.
		FVector PoleToPlayerDirection = PoleClimbComp.GetPoleToPlayerVector();
		PoleRelativeStartLocation = Player.ActorLocation;
		PoleRelativeTargetLocation = PoleClimbComp.Data.ActivePole.ActorLocation;
		PoleRelativeTargetLocation += PoleClimbComp.Data.ActivePole.ActorUpVector * PoleClimbComp.Data.CurrentHeight;
		PoleRelativeTargetLocation += PoleToPlayerDirection * 45.0;
		StartRot = Player.ActorRotation;
		TargetRot = (PoleToPlayerDirection * -1.0).Rotation();
		TargetRot = FRotator::MakeFromXZ(TargetRot.ForwardVector, PoleClimbComp.Data.ActivePole.ActorUpVector * PoleClimbComp.Data.ClimbDirectionSign);

		PoleRelativeTargetLocation = PoleClimbComp.Data.ActivePole.ActorTransform.InverseTransformPosition(PoleRelativeTargetLocation);
		PoleRelativeStartLocation = PoleClimbComp.Data.ActivePole.ActorTransform.InverseTransformPosition(PoleRelativeStartLocation);

		//Check for turnaround enter
		if (PoleClimbComp.Data.ActivePole.bTurnAroundOnEnter)
		{
			APoleClimbActor Pole = PoleClimbComp.Data.ActivePole;

			FVector PoleToPlayer = PoleClimbComp.GetPoleToPlayerVector();
			FVector OppositeDirection = PoleClimbComp.GetClosestPoleAllowedDirection(-PoleToPlayer);

			if (Pole.bAllowFull360Rotation)
				OppositeDirection = -PoleToPlayer;

			if(!IsDirectionObstructed(OppositeDirection))
			{
				TurnAroundStartAngle = Math::DirectionToAngleDegrees(FVector2D(PoleRelativeStartLocation.X, PoleRelativeStartLocation.Y));

				FVector RelativeOppositeDirection = Pole.ActorTransform.InverseTransformVector(OppositeDirection);
				TurnAroundTargetAngle = Math::DirectionToAngleDegrees(FVector2D(RelativeOppositeDirection.X, RelativeOppositeDirection.Y));

				float ClockwiseDistance = Math::GetAngleDegreesInDirection(TurnAroundStartAngle, TurnAroundTargetAngle, true);
				float CounterClockwiseDistance = Math::GetAngleDegreesInDirection(TurnAroundStartAngle, TurnAroundTargetAngle, false);
				bTurnAroundClockwise = Math::Abs(ClockwiseDistance) <= Math::Abs(CounterClockwiseDistance);

				// If pole is upside down, clockwise-ness is flipped.
				if(PoleClimbComp.Data.ClimbDirectionSign < 0)
					bTurnAroundClockwise = !bTurnAroundClockwise;

				FVector MidwayDirection = PoleToPlayer.RotateAngleAxis(bTurnAroundClockwise ? 90 : - 90, Pole.ActorUpVector);
				
				bool bValidTurnaround = false;
				//Check our initial wanted rotation direction for obstructions
				if(IsDirectionObstructed(MidwayDirection))
				{
					//Initial wanted had obstructions, check opposite
					if(IsDirectionObstructed(-MidwayDirection))
					{
						//both sides were blocked
					}
					else
					{
						//Opposite was clear, flip our planned rotation path
						bValidTurnaround = true;
						bTurnAroundClockwise = !bTurnAroundClockwise;
					}
				}
				else
					bValidTurnaround = true;

				if(bValidTurnaround)
				{
					PoleClimbComp.AnimData.bPerformingLeftTurnAround = bTurnAroundClockwise;
					PoleClimbComp.AnimData.bPerformingRightTurnAround = !bTurnAroundClockwise;

					PoleClimbComp.Data.bPerformingTurnaroundEnter = true;
					PoleClimbComp.AnimData.bTurnAroundEnter = true;

					UForceFeedbackEffect FFEffect = PoleClimbComp.TurnAroundFF;
					if (PerspectiveModeComp.PerspectiveMode == EPlayerMovementPerspectiveMode::SideScroller)
					{
						FVector CameraDir = Player.ViewRotation.ForwardVector.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
						FVector PlayerDir = Player.ActorForwardVector;
						FVector CrossProd = CameraDir.CrossProduct(PlayerDir);
						FFEffect = CrossProd.Z < 0.0 ? PoleClimbComp.TurnAroundEnterFFLeft : PoleClimbComp.TurnAroundEnterFFRight;
					}

					Player.PlayForceFeedback(FFEffect, false, true, this);
				}
			}
		}
		else
		{
			Player.PlayForceFeedback(PoleClimbComp.DefaultEnterFF, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPlayerPoleClimbEnterDeactivationParams Params)
	{
		Player.UnblockCapabilities(BlockedWhileIn::PoleClimb, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);

		if (!Params.bMoveFinished)
		{
			if (PoleClimbComp.Data.State == EPlayerPoleClimbState::Enter)
				PoleClimbComp.StopClimbing();

			return;
		}

		PoleClimbComp.AnimData.bInEnter = false;
		PoleClimbComp.AnimData.bTurnAroundEnter = false;
		PoleClimbComp.Data.bPerformingTurnaroundEnter = false;
		PoleClimbComp.AnimData.bPerformingLeftTurnAround = false;
		PoleClimbComp.AnimData.bPerformingRightTurnAround = false;
		PoleClimbComp.SetState(EPlayerPoleClimbState::Climbing);

		if(PoleClimbComp.Data.ActivePole != nullptr)
			PoleClimbComp.Data.ActivePole.OnEnterFinished.Broadcast(Player, PoleClimbComp.Data.ActivePole);
		
		UPlayerCoreMovementEffectHandler::Trigger_Pole_Enter_Finished(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		APoleClimbActor Pole = PoleClimbComp.Data.ActivePole;
		FVector TransformedTargetLocation = PoleClimbComp.Data.ActivePole.ActorTransform.TransformPosition(PoleRelativeTargetLocation);
		FVector TransformedStartLocation = PoleClimbComp.Data.ActivePole.ActorTransform.TransformPosition(PoleRelativeStartLocation);

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{		
				FVector NewLoc;
				FRotator NewRot;

				if (PoleClimbComp.Data.bPerformingTurnaroundEnter)
				{	
					float Alpha = Math::Clamp(ActiveDuration / PoleClimbComp.Settings.TurnaroundEnterDuration, 0, 1);
					if (Alpha >= 1.0)
						bEnterFinished = true;

					// For upside down poles we need to flip the clockwise-ness to rotate in the intended direction.
					bool bRotateClockwise = PoleClimbComp.Data.ClimbDirectionSign < 0 ? !bTurnAroundClockwise : bTurnAroundClockwise;
					float Angle = Math::LerpAngleDegreesInDirection(
						TurnAroundStartAngle, TurnAroundTargetAngle,
						ActiveDuration / PoleClimbComp.Settings.TurnaroundEnterDuration,
						bRotateClockwise,
					);

					FVector2D OffsetDirection = Math::AngleDegreesToDirection(Angle);
					FVector OffsetVector = Pole.ActorTransform.TransformVector(
						FVector(OffsetDirection.X, OffsetDirection.Y, 0.0)
					);

					//Lerp the Offset from the pole
					float OffsetAlpha = Math::GetMappedRangeValueClamped(FVector2D(0.0, 0.25), FVector2D(0.0, 1.0), Alpha);
					float StartOffset = TransformedStartLocation.Dist2D(Pole.ActorLocation, Pole.ActorUpVector);
					float CurrentOffset = Math::Lerp(StartOffset, PoleClimbComp.Settings.PlayerPoleHorizontalOffset, OffsetAlpha);

					NewLoc = PoleClimbComp.Data.ActivePole.ActorLocation;
					NewLoc += PoleClimbComp.Data.ActivePole.ActorUpVector * PoleClimbComp.Data.CurrentHeight;
					NewLoc += OffsetVector * CurrentOffset;
					NewRot = (OffsetVector * - 1.0).Rotation();
				}
				else
				{
					float Alpha = Math::Clamp(ActiveDuration / PoleClimbComp.Settings.EnterMoveDuration, 0, 1);
					if (Alpha >= 1.0)
						bEnterFinished = true;

					NewLoc = Math::Lerp(TransformedStartLocation, TransformedTargetLocation, Alpha);
					NewRot = Math::LerpShortestPath(StartRot, TargetRot, Alpha);
				}

				Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, FVector::ZeroVector);
				Movement.SetRotation(NewRot);
				Movement.IgnoreSplineLockConstraint();
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			// If jump is pressed while we're entering, buffer the jumpoff
			if (WasActionStartedDuringTime(ActionNames::MovementJump, 0.05))
				PoleClimbComp.Data.bJumpOffBuffered = true;
			
			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"PoleClimb", this);
		}
	}

	//Check if we have clearance to perform the turnaround
	bool IsDirectionObstructed(FVector Direction)
	{
#if !RELEASE
		FTemporalLog TempLog = TEMPORAL_LOG(this);
#endif

		FVector Location = PoleClimbComp.Data.ActivePole.ActorLocation + (PoleClimbComp.Data.ActivePole.ActorUpVector * PoleClimbComp.Data.CurrentHeight) + (Direction * PoleClimbComp.Settings.PlayerPoleHorizontalOffset);

		FHazeTraceSettings CollisionTrace = Trace::InitFromMovementComponent(MoveComp);
		FOverlapResultArray Overlaps = CollisionTrace.QueryOverlaps(Location);

#if !RELEASE
		TempLog.OverlapResults("ObstructionTrace", Overlaps.GetFirstBlockHit(), CollisionTrace.Shape, CollisionTrace.ShapeWorldOffset);
#endif
		if(Overlaps.HasBlockHit())
			return true;

		return false;
	}
};


struct FPlayerPoleClimbEnterActivationParams
{
	FPoleClimbEnterTestData TestData;
}

struct FPlayerPoleClimbEnterDeactivationParams
{
	bool bMoveFinished = false;
}