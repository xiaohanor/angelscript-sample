struct FPlayerPoleClimbTurnaroundActivationParams
{
	bool bClockWise = false;
}

class UPlayerPoleClimbTurnaroundCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::PoleClimb);
	default CapabilityTags.Add(PlayerPoleClimbTags::PoleClimbTurnaround);

	default DebugCategory  = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 24;
	default TickGroupSubPlacement = 4;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UPlayerPoleClimbComponent PoleClimbComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	float StartAngle;
	float TargetAngle;
	bool bClockwise;

	bool bTurnaroundInputHeld = false;
	float TurnaroundInputCooldown = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		PoleClimbComp = UPlayerPoleClimbComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerPoleClimbTurnaroundActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!PoleClimbComp.IsClimbing())
			return false;

		if (PoleClimbComp.GetState() != EPlayerPoleClimbState::Climbing)
			return false;

		if (PoleClimb::bEnable2DPoleClimb)
		{
			if (PerspectiveModeComp.IsIn2DPerspective())
				return false;
		}

		if (!PoleClimbComp.Data.ActivePole.bAllowAnyRotation)
			return false;

		if (PoleClimbComp.Data.ActivePole.bFaceBackTowardsInputDirection)
		{
			if (PerspectiveModeComp.IsIn3DPerspective())
				return false;
		}
		else
		{
			if (PoleClimbComp.Data.ActivePole.bAllowFull360Rotation && PerspectiveModeComp.IsIn3DPerspective())
				return false;
		}

		if (DeactiveDuration < PoleClimbComp.Settings.TurnAroundCooldown)
			return false;

		FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);

		// Don't allow turnaround if our input is mostly up or down
		if (Math::Abs(MoveInput.X) < 0.5)
			return false;
		if (Math::Abs(MoveInput.Y) > 0.4)
			return false;

		FVector PoleToPlayer = PoleClimbComp.GetPoleToPlayerVector();
		FVector CurrentDirection = PoleClimbComp.GetClosestPoleAllowedDirection(PoleToPlayer);
		FVector OppositeDirection = PoleClimbComp.GetNextPoleAllowedDirection(PoleToPlayer, MoveComp.MovementInput);

		if (Math::Abs(CurrentDirection.DotProduct(Player.ViewRotation.RightVector)) >= 0.65)
		{
			// If we are looking mostly from the side, treat the horizontal input as the direction we want to go it
			FVector WantedDirection = Player.ViewRotation.RightVector * MoveInput.X;
			if (WantedDirection.IsNearlyZero())
				return false;

			float AngleToCurrent = CurrentDirection.GetAngleDegreesTo(MoveComp.MovementInput);
			float AngleToOpposite = OppositeDirection.GetAngleDegreesTo(MoveComp.MovementInput);

			if (AngleToOpposite < AngleToCurrent - 15.0)
			{
				FVector PlayerMidTurnCardinal = CurrentDirection.RotateAngleAxis(MoveInput.X < 0.0 ? 90 : -90, PoleClimbComp.Data.ActivePole.ActorUpVector);
				//Check for blocking hit at our endlocation
				if(!IsDirectionObstructed(PoleClimbComp.GetClosestPoleAllowedDirection(-PoleToPlayer)))
				{
					//Check for blocking hit at our midway / turn direction cardinal
					if(IsDirectionObstructed(PlayerMidTurnCardinal))
					{
						return false;
					}
					else
						return true;
				}
			}

			return false;
		}
		else
		{
			// If we are looking forward and backward, treat the horizontal input as a decision to turn around
			// The player must release the stick back to neutral before we allow a second turnaround
			if (TurnaroundInputCooldown > 0.0)
				return false;
			
			FVector PlayerTargetCardinal = CurrentDirection.RotateAngleAxis(MoveInput.X < 0.0 ? 90 : -90, PoleClimbComp.Data.ActivePole.ActorUpVector);
			if(IsDirectionObstructed(PlayerTargetCardinal))
				return false;

			return true;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		
		if (!PoleClimbComp.IsClimbing())
			return true;

		if (PoleClimbComp.Data.ActivePole == nullptr)
			return true;

		if (!PoleClimbComp.IsWithinValidClimbHeight())
			return true;

		if (PoleClimbComp.GetState() != EPlayerPoleClimbState::Climbing)
			return true;

		if (ActiveDuration > PoleClimbComp.Settings.TurnAroundDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerPoleClimbTurnaroundActivationParams Params)
	{
		APoleClimbActor Pole = PoleClimbComp.Data.ActivePole;

		PoleClimbComp.Data.bPerformingTurnaround = true;
		PoleClimbComp.Data.TurnAroundStartTime = Time::GameTimeSeconds;

		FVector PoleToPlayer = PoleClimbComp.GetPoleToPlayerVector();
		FVector OppositeDirection = PoleClimbComp.GetNextPoleAllowedDirection(PoleToPlayer, MoveComp.MovementInput);

		FVector RelativePoleToPlayer = Pole.ActorTransform.InverseTransformVector(PoleToPlayer);
		FVector RelativeOppositeDirection = Pole.ActorTransform.InverseTransformVector(OppositeDirection);

		StartAngle = Math::DirectionToAngleDegrees(FVector2D(RelativePoleToPlayer.X, RelativePoleToPlayer.Y));
		TargetAngle = Math::DirectionToAngleDegrees(FVector2D(RelativeOppositeDirection.X, RelativeOppositeDirection.Y));

		PoleClimbComp.Data.TurnAroundTargetPoleToPlayer = OppositeDirection;

		FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);

		bClockwise = (MoveInput.X < 0.0);
		bTurnaroundInputHeld = true;
		TurnaroundInputCooldown = 1.2;

		PoleClimbComp.AnimData.bPerformingLeftTurnAround = bClockwise;
		PoleClimbComp.AnimData.bPerformingRightTurnAround = !bClockwise;

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

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PoleClimbComp.Data.bPerformingTurnaround = false;
		PoleClimbComp.AnimData.bPerformingLeftTurnAround = false;
		PoleClimbComp.AnimData.bPerformingRightTurnAround = false;

		if(PoleClimbComp.Data.ActivePole != nullptr)
			PoleClimbComp.Data.ActivePole.OnPoleTurnaround.Broadcast(Player, PoleClimbComp.Data.ActivePole, PoleClimbComp.Data.TurnAroundTargetPoleToPlayer);
	}
	
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (bTurnaroundInputHeld)
		{
			FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
			if (Math::Abs(MoveInput.X) <= 0.1)
			{
				bTurnaroundInputHeld = false;
				TurnaroundInputCooldown = 0.0;
			}
			else
			{
				TurnaroundInputCooldown -= DeltaTime;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		APoleClimbActor Pole = PoleClimbComp.Data.ActivePole;

		// For upside down poles we need to flip the clockwise-ness to rotate in the intended direction.
		bool bRotateClockwise = PoleClimbComp.Data.ClimbDirectionSign < 0 ? !bClockwise : bClockwise;
		float Angle = Math::LerpAngleDegreesInDirection(
			StartAngle, TargetAngle,
			ActiveDuration / PoleClimbComp.Settings.TurnAroundDuration,
			bRotateClockwise,
		);

		FVector2D OffsetDirection = Math::AngleDegreesToDirection(Angle);
		FVector OffsetVector = Pole.ActorTransform.TransformVector(
			FVector(OffsetDirection.X, OffsetDirection.Y, 0.0)
		);

		PoleClimbComp.Data.TurnAroundRotation = FRotator::MakeFromZX(
			Pole.ActorUpVector * PoleClimbComp.Data.ClimbDirectionSign, -OffsetVector
		);

		// If jump is pressed while we're turning around, buffer the jumpoff until after the turnaround is done
		if (WasActionStarted(ActionNames::MovementJump))
			PoleClimbComp.Data.bJumpOffBuffered = true;
	}

	//Check if we have clearance to perform the turnaround
	bool IsDirectionObstructed(FVector Direction) const
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