
class UPlayerStrafeFloorCapability : UHazePlayerCapability
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

	bool bPerformingInitialTurn = false;
	float InitialTurnAngleDiff = 0;
	float InitialTurnDuration = 0;

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
		bTurning = false;
		CurrentTurnTime = 0;

		Direction = MoveComp.HorizontalVelocity.GetSafeNormal();

		{	// FB: Added this to reset the interpolated rotation to prevent snapping back to the previous rotation when re-entering this strafe capability.
			StartRotation = StrafeComp.GetDefaultFacingRotation(Player);
			InitialTargetRotation = StartRotation;

			//Check if our inital turn angle is outside of our accepted range
			InitialTurnAngleDiff = InitialTargetRotation.AngularDistance(Player.ActorForwardVector.ToOrientationRotator());
			if(InitialTurnAngleDiff > StrafeFloorComp.Settings.StationaryStepCorrectionAngle)
			{
				bPerformingInitialTurn = true;
				StartRotation = Player.ActorForwardVector.Rotation();
				
				if(Player.IsAnyCapabilityActive(n"GravityWhip"))
					Player.SetAnimBoolParam(n"RequestingMeshUpperBodyOverrideAnimation", true);

				//Calculate our anim data for which direction we are turning / Enforce a specific turndirection if at precisely 180 turn

				if(InitialTurnAngleDiff == 180)
				{
					//Offset our initial rotation slightly to make sure we turn in one direction
					StartRotation = FRotator(StartRotation.Pitch, StartRotation.Yaw + 1, StartRotation.Roll);
					StrafeComp.AnimData.InitialTurnDirection = ELeftRight::Right;
				}
				else
				{
					if(Player.ViewRotation.RightVector.DotProduct(Player.ActorForwardVector) > 0)
					{
						StrafeComp.AnimData.InitialTurnDirection = ELeftRight::Left;
					}
					else
					{
						StrafeComp.AnimData.InitialTurnDirection = ELeftRight::Right;
					}
				}

				InitialTurnDuration = InitialTurnAngleDiff / (180 / 0.21);
				InitialTurnDuration = Math::Max(InitialTurnDuration, 0.09);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::FloorMotion, this);
		Player.UnblockCapabilities(BlockedWhileIn::Strafe, this);

		bPerformingInitialTurn = false;

		Player.SetAnimBoolParam(n"RequestingMeshUpperBodyOverrideAnimation", false);
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
				float TargetSpeed = Math::Lerp(StrafeFloorComp.Settings.MinimumSpeed, StrafeFloorComp.Settings.MaximumSpeed, SpeedAlpha) * MoveComp.MovementSpeedMultiplier * StrafeComp.Settings.StrafeMoveScale;

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

				if(bPerformingInitialTurn)
				{
					//We entered strafe with a large turn detected
					//We might also want to force a certain whip / rotation direction if we are doing a straight 180
					
					CurrentTurnTime += DeltaTime;
					const float TurnAlpha = Math::Min(CurrentTurnTime / InitialTurnDuration, 1.0);
					const FRotator NewRotation = Math::LerpShortestPath(StartRotation, InitialTargetRotation, TurnAlpha);

					Movement.SetRotation(NewRotation);

					if(TurnAlpha == 1.0)
					{
						bPerformingInitialTurn = false;
					}
				}
				else if (HorizontalVelocity.IsNearlyZero(1.0))
				{
					//Handle Stationary Rotation

					FVector FlatCameraForward = Player.ControlRotation.ForwardVector.ConstrainToPlane(MoveComp.WorldUp);
					const float CameraAngleFromPlayerRotation = Math::RadiansToDegrees(FlatCameraForward.AngularDistance(Player.ActorForwardVector));

					if (StrafeComp.AnimData.StationaryTurnMode == EStrafeStationaryTurnMode::Smooth)
					{
						/*
							Smooth: will create an angle 'clamp' for the player's rotation and push them around smoothly if they are outside of this clamp
						*/
						const float AngleDirection = Math::Sign(Player.ActorRightVector.DotProduct(FlatCameraForward));
						const float AngularDelta = Math::Max(CameraAngleFromPlayerRotation - StrafeFloorComp.Settings.StationarySmoothAngleClamp, 0.0) * AngleDirection;

						FQuat NewRotation = Player.ActorQuat;
						NewRotation = FQuat(MoveComp.WorldUp, Math::DegreesToRadians(AngularDelta)) * NewRotation;
						Movement.SetRotation(NewRotation);

						StrafeComp.AnimData.StationarySmoothTurnRate = AngularDelta / DeltaTime;
					}
					else if (StrafeComp.AnimData.StationaryTurnMode == EStrafeStationaryTurnMode::Step)
					{
						/*
							Step: Will rotate over time in steps until it gets close enough to the target
							* Unless we detected a large enter turn in which that will be performed first
						*/

						if (!bTurning && Math::Abs(CameraAngleFromPlayerRotation) >= StrafeFloorComp.Settings.StationaryStepCorrectionAngle)
						{
							//If we are not turning / Not in initial turn and we have more then 22.5 degrees to turn then calculate what our turn will look like
							bTurning = true;
							CurrentTurnTime = 0.0;

							// Calculate how many steps this turn will be
							const int MaxNumberOfSteps = 2;
							const int NumberOfSteps = Math::Min(Math::RoundToInt(CameraAngleFromPlayerRotation / StrafeFloorComp.Settings.StationaryStepAngle), MaxNumberOfSteps);
							const float TurnAngle = NumberOfSteps * StrafeFloorComp.Settings.StationaryStepAngle;

							StartRotation = Owner.ActorRotation;

							FQuat RotatedTarget = StartRotation.Quaternion();
							float RotateDegrees = TurnAngle * Math::Sign(Player.ActorRightVector.DotProduct(FlatCameraForward));
							RotatedTarget = FQuat(MoveComp.WorldUp, Math::DegreesToRadians(RotateDegrees)) * RotatedTarget;

							InitialTargetRotation = RotatedTarget.Rotator();


							StrafeComp.AnimData.StationaryStepInitialAngle = TurnAngle * Math::Sign(Player.ActorRightVector.DotProduct(FlatCameraForward));
							StrafeComp.AnimData.bTurning = true;
						}

						if (bTurning)
						{
							CurrentTurnTime += DeltaTime;

							// Allow some offset from the initial target
							const float AngularDistanceFromTarget = Math::RadiansToDegrees(FlatCameraForward.AngularDistance(InitialTargetRotation.ForwardVector));
							const float CorrectionAngle = Math::Min(AngularDistanceFromTarget, StrafeFloorComp.Settings.StationaryStepCorrectionAngle) * Math::Sign(InitialTargetRotation.RightVector.DotProduct(FlatCameraForward));

							FQuat RotatedTarget = InitialTargetRotation.Quaternion();
							RotatedTarget = FQuat(MoveComp.WorldUp, Math::DegreesToRadians(CorrectionAngle)) * RotatedTarget;
							TargetRotation = RotatedTarget.Rotator();

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

					FRotator NewRotation = Math::RInterpConstantShortestPathTo(Owner.ActorRotation, TargetFacingRotation, DeltaTime, StrafeComp.Settings.FacingDirectionInterpSpeed);
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