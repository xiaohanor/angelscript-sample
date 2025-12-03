
class UGenericGoatStrafeFloorMotionCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Strafe);
	default CapabilityTags.Add(PlayerMovementTags::FloorMotion);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 140;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UPlayerStrafeFloorComponent StrafeFloorComp;
	UPlayerStrafeComponent StrafeComp;

	float CurrentSpeed = 0.0;
	FVector Direction = FVector::ZeroVector;
	bool bReachedDesiredRotation = false;

	bool bTurning = false;
	float CurrentTurnTime = 0.0;
	FRotator StartRotation;
	FRotator InitialTargetRotation;
	FRotator TargetRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();

		StrafeFloorComp = UPlayerStrafeFloorComponent::GetOrCreate(Player);
		StrafeComp = UPlayerStrafeComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!StrafeComp.IsStrafeEnabled())
			return false;

		// This impulse will bring us up in the air, so dont activate
		if(MoveComp.HasUpwardsImpulse())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!StrafeComp.IsStrafeEnabled())
			return true;

		if (!MoveComp.IsOnWalkableGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::FloorMotion, this);
		Player.BlockCapabilities(BlockedWhileIn::Strafe, this);

		CurrentSpeed = MoveComp.HorizontalVelocity.Size();
		bReachedDesiredRotation = false;

		StrafeComp.AnimData.bTurning = false;

		{	// FB: Added this to reset the interpolated rotation to prevent snapping back to the previous rotation when re-entering this strafe capability.
			StartRotation = StrafeComp.GetDefaultFacingRotation(Player);
			InitialTargetRotation = StartRotation;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::FloorMotion, this);
		Player.UnblockCapabilities(BlockedWhileIn::Strafe, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FRotator TargetFacingRotation = StrafeComp.GetDefaultFacingRotation(Player);
		Player.SetMovementFacingDirection(TargetFacingRotation);

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				StrafeComp.AnimData.bHasInput = !MoveComp.MovementInput.IsNearlyZero();
				
				FVector TargetDirection = MoveComp.MovementInput;
				Direction = Math::VInterpConstantTo(Direction, TargetDirection, DeltaTime, 15.0);

				// Calculate the target speed
				float SpeedAlpha = Math::Clamp((MoveComp.MovementInput.Size() - StrafeFloorComp.Settings.MinimumInput) / (1.0 - StrafeFloorComp.Settings.MinimumInput), 0.0, 1.0);
				float TargetSpeed = Math::Lerp(StrafeFloorComp.Settings.MinimumSpeed, StrafeFloorComp.Settings.MaximumSpeed, SpeedAlpha) * MoveComp.MovementSpeedMultiplier * StrafeComp.Settings.StrafeMoveScale * 1.5;

				if(MoveComp.MovementInput.IsNearlyZero())
					TargetSpeed = 0.0;
			
				// Update new velocity
				float InterpSpeed = StrafeFloorComp.Settings.AccelerateInterpSpeed;
				if(TargetSpeed < CurrentSpeed)
					InterpSpeed = StrafeFloorComp.Settings.DecelerateInterpSpeed;
				CurrentSpeed = Math::FInterpTo(MoveComp.HorizontalVelocity.Size(), TargetSpeed, DeltaTime, InterpSpeed);
				FVector HorizontalVelocity = Direction.GetSafeNormal() * CurrentSpeed;
	
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.AddHorizontalVelocity(HorizontalVelocity);

				if (HorizontalVelocity.IsNearlyZero(1.0))
				{
					FRotator CameraRotation = Player.ControlRotation;
					CameraRotation.Pitch = 0.0;

					FVector CameraForward = CameraRotation.ForwardVector;
					const float CameraAngleFromPlayerRotation = Math::RadiansToDegrees(CameraForward.AngularDistance(Player.ActorForwardVector));

					if (StrafeComp.AnimData.StationaryTurnMode == EStrafeStationaryTurnMode::Smooth)
					{
						/*
							Smooth: will create an angle 'clamp' for the player's rotation and push them around smoothly if they are outside of this clamp
						*/
						const float AngleDirection = Math::Sign(Player.ActorRightVector.DotProduct(CameraForward));
						const float AngularDelta = Math::Max(CameraAngleFromPlayerRotation - StrafeFloorComp.Settings.StationarySmoothAngleClamp, 0.0) * AngleDirection;

						FRotator NewRotation = Player.ActorRotation;
						NewRotation.Yaw += AngularDelta;
						Movement.SetRotation(NewRotation);

						StrafeComp.AnimData.StationarySmoothTurnRate = AngularDelta / DeltaTime;
					}
					else if (StrafeComp.AnimData.StationaryTurnMode == EStrafeStationaryTurnMode::Step)
					{
						/*
							Step: Will rotate over time in steps until it gets close enough to the target
						*/
						if (!bTurning && Math::Abs(CameraAngleFromPlayerRotation) >= 22.5)
						{
							bTurning = true;
							CurrentTurnTime = 0.0;

							// Calculate how many steps this turn will be
							const int MaxNumberOfSteps = 2;
							const int NumberOfSteps = Math::Min(Math::RoundToInt(CameraAngleFromPlayerRotation / StrafeFloorComp.Settings.StationaryStepAngle), MaxNumberOfSteps);
							const float TurnAngle = NumberOfSteps * StrafeFloorComp.Settings.StationaryStepAngle;

							StartRotation = Owner.ActorRotation;
							InitialTargetRotation = StartRotation;
							InitialTargetRotation.Yaw += TurnAngle * Math::Sign(Player.ActorRightVector.DotProduct(CameraForward));

							StrafeComp.AnimData.StationaryStepInitialAngle = TurnAngle * Math::Sign(Player.ActorRightVector.DotProduct(CameraForward));
							StrafeComp.AnimData.bTurning = true;
						}

						if (bTurning)
						{
							CurrentTurnTime += DeltaTime;

							// Allow some offset from the initial target
							const float AngularDistanceFromTarget = Math::RadiansToDegrees(CameraForward.AngularDistance(InitialTargetRotation.ForwardVector));
							const float CorrectionAngle = Math::Min(AngularDistanceFromTarget, StrafeFloorComp.Settings.StationaryStepCorrectionAngle) * Math::Sign(InitialTargetRotation.RightVector.DotProduct(CameraForward));

							TargetRotation = InitialTargetRotation;
							TargetRotation.Yaw += CorrectionAngle;

							const float TurnAlpha = Math::Min(CurrentTurnTime / StrafeFloorComp.Settings.StationaryStepTurnTime, 1.0);
							const FRotator NewRotation = Math::LerpShortestPath(StartRotation, TargetRotation, TurnAlpha);
							Movement.SetRotation(NewRotation);

							StrafeComp.AnimData.StationaryStepTargetAngle = StrafeComp.AnimData.StationaryStepInitialAngle + CorrectionAngle;
							StrafeComp.AnimData.StationaryStepTurnAlpha = TurnAlpha;

							if (TurnAlpha == 1.0)
							{
								bTurning = false;
								StrafeComp.AnimData.bTurning = false;
							}
						}
					}
				}
				else
				{
					bTurning = false;
					StrafeComp.AnimData.bTurning = false;

					TargetFacingRotation.Pitch = 0.0;
					FRotator NewRotation = Math::RInterpConstantTo(Owner.ActorRotation, TargetFacingRotation, DeltaTime, StrafeComp.Settings.FacingDirectionInterpSpeed);
					Movement.SetRotation(NewRotation);
				}
				

				FVector RelativeVelocity = Owner.ActorTransform.InverseTransformVectorNoScale(HorizontalVelocity);
				StrafeComp.AnimData.BlendSpaceVector = FVector2D(RelativeVelocity.Y, RelativeVelocity.X);				

				if (IsDebugActive())
				{
					PrintToScreenScaled("Vel: " + Player.GetActorRotation().UnrotateVector(MoveComp.HorizontalVelocity) + " | " + Math::RoundToFloat(MoveComp.HorizontalVelocity.Size()));
					PrintToScreenScaled("SpeedAlpha: " + SpeedAlpha);
					PrintToScreenScaled("TargetSpeed: " + TargetSpeed);
				}
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"StrafeFloor");
		}
	}
}