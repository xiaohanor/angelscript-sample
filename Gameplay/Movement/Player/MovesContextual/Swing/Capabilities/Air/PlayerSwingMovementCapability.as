
class UPlayerSwingMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Swing);
	default CapabilityTags.Add(PlayerSwingTags::SwingMovement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 38;
	default TickGroupSubPlacement = 23;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 18, 20);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AHazePlayerCharacter Player;
	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;
	
	UPlayerSwingComponent SwingComp;
	UPlayerTargetablesComponent TargetablesComp;

	USwingPointComponent AttachedSwingPoint;
	uint64 AttachDelegateHandle;
	FVector SwingAttachPosition;
	FQuat SwingAttachRotation;

	FRotator InitialAttachRotation;

	FVector SwingInputMaintainedDirection;
	float SwingInputMaintainedTime = 0.0;

	bool bHaveSwingPointVelocity = false;
	FVector PreviousSwingPointVelocity;

	float TimeSinceInput = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();

		SwingComp = UPlayerSwingComponent::GetOrCreate(Player);
		TargetablesComp = UPlayerTargetablesComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!SwingComp.HasActivateSwingPoint())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSwingAirDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!SwingComp.HasActivateSwingPoint())
		{
			Params.bSwingPointInvalidated = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SwingComp.AnimData.State = EPlayerSwingState::Swing;

		FVector FlatFacing = SwingComp.PlayerToSwingPoint.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		InitialAttachRotation = FRotator::MakeFromXZ(FlatFacing, MoveComp.WorldUp);

		SwingInputMaintainedTime = 0.0;
		TimeSinceInput = 0.0;

		if (HasControl())
		{
			if (SwingComp.Data.ActiveSwingPoint.bApplyInertiaFromMovingSwingPoint)
			{
				AttachedSwingPoint = SwingComp.Data.ActiveSwingPoint;
				SwingAttachPosition = AttachedSwingPoint.WorldLocation;
				SwingAttachRotation = AttachedSwingPoint.ComponentQuat;
				AttachDelegateHandle = SceneComponent::BindOnSceneComponentMoved(AttachedSwingPoint, FOnSceneComponentMoved(this, n"OnSwingPointMoved"));
			}
		}
	}

	UFUNCTION()
	private void OnSwingPointMoved(USceneComponent MovedComponent, bool bIsTeleport)
	{
		float InertiaFactor = AttachedSwingPoint.MovingSwingInertiaFactor;
		if (bIsTeleport)
			InertiaFactor = 0.0;

		FVector NewPosition = MovedComponent.WorldLocation;
		FQuat NewRotation = MovedComponent.ComponentQuat;

		FVector PlayerLocation = SwingComp.GetPlayerLocation();

		// The player doesn't move with the swing point except to maintain the length of the rope
		float TetherLengthBeforeMove = SwingAttachPosition.Distance(PlayerLocation);

		// Apply the part of the movement that should not be subject to inertia
		FVector SwingPointMovement = NewPosition - SwingAttachPosition;
		FVector NonInertiaMovement = SwingPointMovement * (1.0 - InertiaFactor);
		PlayerLocation += NonInertiaMovement;

		// Apply the part of the movement that should be subject to inertia
		FVector TetherVectorAfterMove = PlayerLocation - NewPosition;

		FVector PlayerLocationAfterMove = NewPosition + TetherVectorAfterMove.GetSafeNormal() * TetherLengthBeforeMove;
		FVector PlayerDelta = PlayerLocationAfterMove - PlayerLocation;

		FVector NewPlayerLocation = Player.ActorLocation + PlayerDelta + NonInertiaMovement;
		FQuat NewPlayerRotation = Player.ActorQuat;

		if (AttachedSwingPoint.bFollowYawRotationOfSwingPoint)
		{
			FQuat DeltaRotation = NewRotation * SwingAttachRotation.Inverse();
			FVector NewForward = DeltaRotation * Player.ActorForwardVector;

			FVector YawAxis = Player.ActorUpVector;
			NewPlayerRotation = FQuat::MakeFromZX(YawAxis, NewForward);
		}

		Player.SetActorLocationAndRotation(NewPlayerLocation, NewPlayerRotation);

		SwingAttachPosition = NewPosition;
		SwingAttachRotation = NewRotation;

#if !RELEASE
		TEMPORAL_LOG(this).Section("SwingInertia")
			.Value("InertiaFactor", InertiaFactor)
			.Value("TetherLengthBeforeMove", TetherLengthBeforeMove)
			.Value("PlayerDelta", PlayerDelta)
			.Value("NonInertiaMovement", NonInertiaMovement)
			.Value("SwingPointMovement", SwingPointMovement)
		;
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSwingAirDeactivationParams Params)
	{	
		if(Params.bSwingPointInvalidated)
			SwingComp.AnimData.State = EPlayerSwingState::Cancel;

		if (IsValid(AttachedSwingPoint))
		{
			SceneComponent::UnbindOnSceneComponentMoved(AttachedSwingPoint, AttachDelegateHandle);
			AttachedSwingPoint = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;
		
		if (SwingComp.Data.bTetherTaut)
			SwingComp.Data.AcceleratedTetherLength.AccelerateTo(SwingComp.Settings.TetherLength, 1.0, DeltaTime);

		if (HasControl())
		{
			FVector Velocity = MoveComp.Velocity;
			FVector PreviousVelocity = Velocity;

			FVector SwingLocation = SwingComp.SwingPointLocation;
			FVector SwingToPlayer = SwingComp.SwingPointToPlayer;
			float PreviousSwingAngle = SwingComp.SwingAngle;

			FVector PlayerToSwingPointDirection = SwingComp.PlayerToSwingPoint.GetSafeNormal();
			FVector BiTangent = MoveComp.WorldUp.CrossProduct(PlayerToSwingPointDirection);
			FVector SwingSlope = BiTangent.CrossProduct(PlayerToSwingPointDirection);				

			// Velocity -= MoveComp.GetFollowVelocity();

			// If our velocity is too fast, we apply drag to the overspeed part
			float PreviousSpeed = Velocity.Size();
			if (PreviousSpeed > SwingComp.Settings.MaximumSwingVelocityBeforeOverspeedDrag)
			{
				float Overspeed = PreviousSpeed - SwingComp.Settings.MaximumSwingVelocityBeforeOverspeedDrag;
				Overspeed *= Math::Pow(SwingComp.Settings.OverspeedDragFactor, DeltaTime);
				PreviousSpeed = SwingComp.Settings.MaximumSwingVelocityBeforeOverspeedDrag + Overspeed;
				
				Velocity = Velocity.GetSafeNormal() * PreviousSpeed;
			}

			if (MoveComp.MovementInput.IsNearlyZero())
			{
				// Player doesn't have input

					/* Try a stronger gravity when you are going away from the center instead of drag
							Might feel more natural
						Drag should probably kick in a few seconds after input isnt pressed, so you continue the current swing you have for a bit
					*/
			
				Velocity *= Math::Pow(SwingComp.Settings.NoInputDragCoefficient, DeltaTime);

				SwingComp.AnimData.PushDirection = FVector2D::ZeroVector;		
				SwingInputMaintainedTime = 0.0;
			}
			else 
			{
				// Player has input

				// Drag
				FVector DragDirection = MoveComp.WorldUp.CrossProduct(MoveComp.MovementInput).GetSafeNormal();
				FVector HorizontalVelocity = DragDirection * Velocity.DotProduct(DragDirection);
				FVector OtherVelocity = Velocity - HorizontalVelocity;

				HorizontalVelocity *= Math::Pow(SwingComp.Settings.HorizontalDragCoefficient, DeltaTime);
				OtherVelocity *= Math::Pow(SwingComp.Settings.VerticalDragCoefficient, DeltaTime);
				Velocity = HorizontalVelocity + OtherVelocity;

				// Movement Acceleration
				FVector MoveInput = MoveComp.MovementInput;

				float VelocityStrength = SwingComp.Settings.InputSpeed * (SwingComp.Data.TetherLength / SwingComp.Settings.RopeLength);

				// Determine how long the player has been holding input in the same direction
				if (MoveInput.AngularDistance(SwingInputMaintainedDirection) < 0.1 * PI)
				{
					SwingInputMaintainedTime += DeltaTime;
				}
				else
				{
					SwingInputMaintainedTime = 0.0;
					SwingInputMaintainedDirection = MoveInput;
				}
				
				// If we're going slow and we've held input in the same direction for a while,
				// we are allowed to give stronger acceleration to boost us up to a nice swing quicker
				float AnglePct = Math::GetMappedRangeValueClamped(
					FVector2D(35.0, 0.0),
					FVector2D(0.0, 1.0),
					SwingComp.SwingAngle,
				);
				float InputPct = Math::GetMappedRangeValueClamped(
					FVector2D(0.0, 2.0),
					FVector2D(0.0, 1.0),
					SwingInputMaintainedTime,
				);
				float VelocityPct = Math::GetMappedRangeValueClamped(
					FVector2D(900.0, 1000.0),
					FVector2D(1.0, 0.0),
					Velocity.Size(),
				);

				float BoostStrength = Math::Lerp(
					1.0, 10.0,
					AnglePct * InputPct * VelocityPct,
				);
				MoveInput *= BoostStrength;

				// Don't allow slowing down the swing too much, this prevents us from hovering in the air
				float CounterInputLimit = -1.0;
				if (Velocity.Size() > 1.0)
				{
					FVector SwingDirection = Velocity.GetSafeNormal();
					FVector SidewaysInput = MoveInput.ConstrainToPlane(SwingDirection);

					float SwingInput = MoveInput.DotProduct(SwingDirection);
					CounterInputLimit = Math::GetMappedRangeValueClamped(
						FVector2D(500.0, 800.0),
						FVector2D(0.0, -1.0),
						Velocity.Size()
					);

					// CounterInputLimit = 0.0;

					if (SwingInput < CounterInputLimit)
					{
						SwingInputMaintainedTime = 0.0;
						SwingInput = CounterInputLimit;
					}

					MoveInput = SwingDirection * SwingInput + SidewaysInput;
				}

				// Correct input in the direction of velocity
				if (!Velocity.IsNearlyZero())
				{
					// Correct input so that the player can hold forwards and the actual player velocity will be directed towards the direction of travel

					// [Attempt 1] Mirror everything - This causes LEFT and RIGHT to also flip, which is not what we want, dog
					// MoveInput *= Math::Sign(MoveComp.MovementInput.DotProduct(Velocity));

					// [ Attempt 2] Mirror around velocity - This was just shit. Something like this is the right direction, but it needs to not be shit
					// FVector FlattenedVelocityDirection = Velocity.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
					// float ForwardInput = FlattenedVelocityDirection.DotProduct(MoveInput);
					// MoveInput -= FlattenedVelocityDirection * ForwardInput;
					// MoveInput += FlattenedVelocityDirection * ForwardInput * Math::Sign(MoveComp.MovementInput.DotProduct(Velocity));
				}

				Velocity += MoveInput * VelocityStrength * DeltaTime;

				FVector PushDirection = Player.ActorRotation.UnrotateVector(MoveInput);
				SwingComp.AnimData.PushDirection = FVector2D(PushDirection.Y, PushDirection.X);

				if(IsDebugActive())
					Debug::DrawDebugLine(SwingComp.PlayerLocation, SwingComp.PlayerLocation + MoveInput * 150.0, FLinearColor::Yellow, 2.0);

#if !RELEASE
				TEMPORAL_LOG(this)
					.Value("BoostStrength", BoostStrength)
					.Value("VelocityStrength", VelocityStrength)
					.Value("CounterInputLimit", CounterInputLimit)
					.Value("SwingMoveInput", MoveInput)
					.Value("SwingInputMaintainedDirection", SwingInputMaintainedDirection)
					.Value("SwingInputMaintainedTime", SwingInputMaintainedTime)
				;
#endif
			}

			/*	Gravity:
				- If you are moving upwards, and tether not taut: Add normal vertical gravity
				- Else: Add swing gravity
			*/
			FVector GravityAcceleration;
			if (MoveComp.WorldUp.DotProduct(Velocity) > 0.0 && !SwingComp.Data.bTetherTaut)
			{
				GravityAcceleration = -MoveComp.WorldUp * MoveComp.GetGravityForce();
			}
			else
			{
				float GravityScale = Math::Pow(SwingSlope.Size(), 0.75);
				GravityAcceleration = SwingSlope.GetSafeNormal() * GravityScale * SwingComp.Settings.GravityAcceleration;
			}

			// Gravity should be applied as an acceleration directly to DeltaMove so it's not framerate dependent
			FVector DeltaMove = Velocity * DeltaTime;
			DeltaMove += GravityAcceleration * (DeltaTime * DeltaTime * 0.5);
			Velocity += GravityAcceleration * DeltaTime;

			SwingComp.ConstrainVelocityToSwingPoint(Velocity, DeltaMove);

			Movement.AddDeltaWithCustomVelocity(DeltaMove, Velocity);
			Movement.AddPendingImpulses();

			// Rotate Towards Input
			FVector WantedFacing;
			bool bAllowBackwardFacing = true;

			if (!MoveComp.MovementInput.IsNearlyZero())
			{
				// Face towards the input
				WantedFacing = MoveComp.MovementInput.GetSafeNormal();
				TimeSinceInput = 0.0;
			}
			else
			{
				TimeSinceInput += DeltaTime;

				// Face towards the center of the swing
				FVector FlatDirection = -SwingToPlayer.ConstrainToPlane(MoveComp.WorldUp);
				if (FlatDirection.Size() > 20.0)
				{
					WantedFacing = FlatDirection.GetSafeNormal();
				}
				else
				{
					WantedFacing = Player.ActorForwardVector;
					bAllowBackwardFacing = false;
				}
			}

			// We have two potential facings, depending on whether we consider our input forward or backward
			FVector ForwardFacing = WantedFacing;
			FVector BackwardFacing = -WantedFacing;

			FVector BestFacing;
			// If our input is almost directly opposite our current facing, don't change it,
			// we're likely swinging backwards.
			if (bAllowBackwardFacing && BackwardFacing.AngularDistance(Player.ActorForwardVector) < Math::DegreesToRadians(20.0))
				BestFacing = BackwardFacing;
			// Otherwise, change to the movement input facing
			else
				BestFacing = ForwardFacing;

			FRotator TargetRotation = FRotator::MakeFromXZ(BestFacing, MoveComp.WorldUp);
			Movement.SetRotation(Math::RInterpConstantTo(Player.ActorRotation, TargetRotation, DeltaTime,
				90.0 * Math::Max(MoveComp.MovementInput.Size(), 0.5)));			

#if !RELEASE
			// Debug Draw
			if (IsDebugActive())
			{
				SwingComp.DebugDrawVelocity(Velocity, MoveComp.WorldUp * 10.0);
				SwingComp.DebugDrawGravity(GravityAcceleration, -MoveComp.WorldUp * 10.0);

				FRotator TetherPlayerRotation = FRotator::MakeFromZY(SwingComp.PlayerToSwingPoint, Owner.ActorRightVector);

				Debug::DrawDebugLine(SwingComp.PlayerLocation, SwingComp.PlayerLocation + SwingSlope * 150.0, FLinearColor::Blue, 2.0);
				Debug::DrawDebugCoordinateSystem(Player.ActorLocation, TetherPlayerRotation, 150.0, 3.0, 0.0);
			}
#endif

			HandleForceFeedback(DeltaTime);

#if !RELEASE
			FVector SwingBottomLocation = SwingComp.SwingPointLocation - MoveComp.WorldUp * SwingComp.Settings.TetherLength;
			TEMPORAL_LOG(this)
				.DirectionalArrow("PreviousVelocity",
					Player.ActorCenterLocation, PreviousVelocity,
					Color = FLinearColor::DPink)
				.Arrow("SwingToPlayer",
					SwingLocation, Player.ActorCenterLocation,
					Color = FLinearColor::Black)
				.Arrow("SwingAxis",
					SwingBottomLocation, SwingLocation,
					Size = 10.0,
					Color = FLinearColor::Black)
				.Value("PreviousSwingAngle", PreviousSwingAngle)
			;
#endif
		}
		else
		{
			Movement.ApplyCrumbSyncedAirMovement();
			SwingComp.UpdateTetherTautness(MoveComp.GetCrumbSyncedPosition().WorldVelocity);

			// Send input information to the ABP so it can play the right animations
			FVector SyncedInput = MoveComp.GetSyncedMovementInputForAnimationOnly();
			if (SyncedInput.IsNearlyZero())
			{
				SwingComp.AnimData.PushDirection = FVector2D::ZeroVector;		
			}
			else 
			{
				FVector PushDirection = Player.ActorRotation.UnrotateVector(SyncedInput);
				SwingComp.AnimData.PushDirection = FVector2D(PushDirection.Y, PushDirection.X);
			}
		}

		MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"SwingAir");


		if(SwingComp.Data.HasValidSwingPoint())
		{
			// Update Anim Data
			FRotator TetherPlayerRotation = FRotator::MakeFromZY(SwingComp.PlayerToSwingPoint, Owner.ActorRightVector);
			FQuat TetherPlayerRotationRelative = Player.ActorTransform.InverseTransformRotation(TetherPlayerRotation.Quaternion());

			FVector RelativeVelocity = TetherPlayerRotation.UnrotateVector(MoveComp.Velocity);			
			SwingComp.AnimData.SwingRotation = TetherPlayerRotationRelative.Rotator();
			// SwingComp.AnimData.RelativeVelocity = FVector2D(RelativeVelocity.Y, RelativeVelocity.X);
			SwingComp.AnimData.RelativeVelocity = FVector2D(
				Math::FInterpTo(SwingComp.AnimData.RelativeVelocity.X, RelativeVelocity.Y, DeltaTime, 4.0),
				Math::FInterpTo(SwingComp.AnimData.RelativeVelocity.Y, RelativeVelocity.X, DeltaTime, 4.0),
			);
			SwingComp.AnimData.SwingAngle = SwingComp.SwingAngle;

			if (!SwingComp.AnimData.PushDirection.IsNearlyZero())
			{
				float Alpha = Math::Abs(SwingComp.AnimData.PushDirection.Y);
				SwingComp.AnimData.PushDirection = Math::Lerp(SwingComp.AnimData.PushDirection * 1200.0, SwingComp.AnimData.RelativeVelocity, Alpha);
			}

			// SwingComp.AnimData.PushDirection = FVector2D();
			// SwingComp.AnimData.RelativeVelocity = FVector2D();

			// SwingComp.DebugDrawTether();
		}
	}

	void HandleForceFeedback(float DeltaTime)
	{
		if(!SwingComp.Data.bTetherTaut)
			return;
		
		float FF_Frequency = Math::Saturate(MoveComp.Velocity.Size() / 1250);
		FHazeFrameForceFeedback FF;
		FF.RightMotor = (0.25 * Math::Max(0.25, FF_Frequency)) * (Math::Max(0.05, (0.35 * (1 - (Math::Saturate(SwingComp.AnimData.SwingAngle / 50))))) * FF_Frequency);

		Player.SetFrameForceFeedback(FF);
	}
}

struct FSwingAirDeactivationParams
{
	bool bSwingPointInvalidated = false;
}