/*
 *	This capability handles translation/rotation along the pole as well as animation 
 */

class UPlayerPoleClimbMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::PoleClimb);
	default CapabilityTags.Add(PlayerPoleClimbTags::PoleClimbMovement);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 25;
	default TickGroupSubPlacement = 2;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UPlayerPoleClimbComponent PoleClimbComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;
	UHazeCrumbSyncedFloatComponent SyncedTargetSpeedForAnimation;

	float TargetSpeed;
	float TargetHeight;

	//If set to slippery then this is how much of our current speed is involuntary
	float InvoluntarySlipSpeed;

	FVector TargetLocation;
	FRotator TargetRot;

	FVector LastWantedMovementDirection;

	USimpleMovementData Movement;
	FHazeAcceleratedFloat AcceleratedRotationSpeed;

	//Current Velocity will drop us off the bottom of the pole
	bool bWillSlidePastEndPoint = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SyncedTargetSpeedForAnimation = UHazeCrumbSyncedFloatComponent::Create(Player, n"PoleClimbMovementSyncedTargetSpeedForAnimation");
		SyncedTargetSpeedForAnimation.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
		PoleClimbComp = UPlayerPoleClimbComponent::GetOrCreate(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

		if (PoleClimbComp.GetState() == EPlayerPoleClimbState::Climbing)
			return true;
			
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPlayerPoleClimbDeactivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
		{
			if(PoleClimbComp.GetState() == EPlayerPoleClimbState::Climbing)
			{
				//Internal state was not altered, a different move took over
				Params.DeactivationType = EPlayerPoleClimbDeactivationType::Interrupted;
			}
			else
			{
				//Internal state was altered, we transitioned to a different PoleClimb Move
				Params.DeactivationType = EPlayerPoleClimbDeactivationType::Transition;
			}

			return true;
		}

		if(!IsValid(PoleClimbComp.Data.ActivePole))
		{
			Params.DeactivationType = EPlayerPoleClimbDeactivationType::Disabled;
			return true;
		}

		if (PoleClimbComp.Data.ActivePole.IsActorDisabled() || PoleClimbComp.Data.ActivePole.IsPoleDisabled())
		{
			Params.DeactivationType = EPlayerPoleClimbDeactivationType::Disabled;
			return true;
		}

		if(!Player.IsSelectedBy(PoleClimbComp.Data.ActivePole.UsableByPlayers))
		{
			Params.DeactivationType = EPlayerPoleClimbDeactivationType::Disabled;
			return true;
		}	

		if (PoleClimbComp.GetState() != EPlayerPoleClimbState::Climbing && PoleClimbComp.GetState() != EPlayerPoleClimbState::Inactive)
		{
			Params.DeactivationType = EPlayerPoleClimbDeactivationType::Transition;
			return true;
		}

		if(bWillSlidePastEndPoint)
		{
			Params.DeactivationType = EPlayerPoleClimbDeactivationType::ReachedBottom;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// If we came from JumpUp / Dash then set our velocity to be in motion
		if(PoleClimbComp.GetState() == EPlayerPoleClimbState::Dash)
			Player.SetActorVerticalVelocity(MoveComp.VerticalVelocity);

		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);

		AcceleratedRotationSpeed.SnapTo(0.0, 0.0);
		InvoluntarySlipSpeed = 0.0;
		TargetSpeed = 0.0;
		SyncedTargetSpeedForAnimation.Value = 0.0;
		TargetHeight = PoleClimbComp.Data.CurrentHeight;
		LastWantedMovementDirection = FVector::ZeroVector;

		PoleClimbComp.SetState(EPlayerPoleClimbState::Climbing);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPlayerPoleClimbDeactivationParams Params)
	{
		AcceleratedRotationSpeed.SnapTo(0.0, 0.0);
		bWillSlidePastEndPoint = false;

		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);

		switch(Params.DeactivationType)
		{
			case EPlayerPoleClimbDeactivationType::Transition:
			break;

			default:
				PoleClimbComp.StopClimbing();
			break;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(PoleClimbComp.AnimData.DashSideOverrideState != EDashSideOverrideState::Default)
		{
			if(ActiveDuration >= 0.25)
				PoleClimbComp.AnimData.DashSideOverrideState = EDashSideOverrideState::Default;
		}

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{	
				FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);

				ClampInputWithinDeadZones(MoveInput);

				CalculateHeightAndVelocity(DeltaTime, MoveInput);
				HandleMovement(DeltaTime, MoveInput);
				SetAnimationData(MoveInput);
			}
			else
			{
				SetRemoteAnimationData(DeltaTime);
				HandleRemoteMovement();
			}
		}

		Player.Mesh.RequestLocomotion(n"PoleClimb", this);
	}

	//Calculate our current clamped height / translation / Velocity along the pole
	void CalculateHeightAndVelocity(float DeltaTime, FVector2D InInput)
	{
		float SignedVerticalSpeed = (PoleClimbComp.Data.ActivePole.ActorUpVector * PoleClimbComp.Data.ClimbDirectionSign).DotProduct(MoveComp.Velocity);
		const EPoleType ActivePoleType = PoleClimbComp.GetPoleType();
		
		bool bIsSliding = false;

		TargetHeight = PoleClimbComp.Data.CurrentHeight;

		FVector2D Input = InInput;
		if (PoleClimb::bUseAlternateClimbControls)
		{
			Input.X = 0.0;
			if (IsActioning(ActionNames::MovementDash))
				Input.Y = 1.0;
			else if (IsActioning(ActionNames::Cancel))
				Input.Y = -1.0;
			else
				Input.Y = 0.0;
		}

		if(PerspectiveModeComp.GetPerspectiveMode() == EPlayerMovementPerspectiveMode::SideScroller)
			Input.Y = Input.Y * MoveComp.WorldUp.DotProduct(Player.ViewRotation.UpVector);

		if(Input.Y > 0.2 && (ActivePoleType == EPoleType::Default || PoleClimbComp.Data.ActivePole.bAllowClimbingUp))
		{
			//We are climbing upwards
			float RelevantInput = Math::Abs(Input.X) < 0.5 && !PoleClimbComp.Data.ActivePole.bAllowFull360Rotation ? Input.Size() : Input.Y;
			float InputAlpha = Math::GetMappedRangeValueClamped(FVector2D(PoleClimbComp.Settings.VerticalDeadZone, 1.0),FVector2D(0.0, 1.0), RelevantInput);

			float TargetVerticalSpeed = PoleClimbComp.Settings.ClimbSpeed * InputAlpha;
			
			//Enforce a minimum vertical velocity if giving stick input.
			if(Math::Abs(TargetVerticalSpeed) <= PoleClimbComp.Settings.MinimumVerticalSpeed)
				TargetVerticalSpeed = Math::Sign(TargetVerticalSpeed) * PoleClimbComp.Settings.MinimumVerticalSpeed;

			TargetSpeed = Math::FInterpConstantTo(SignedVerticalSpeed, TargetVerticalSpeed, DeltaTime, SignedVerticalSpeed > 0 ? PoleClimbComp.Settings.ClimbInterpSpeed : PoleClimbComp.Settings.SlideBrakeInterpSpeed);
			
			TargetHeight += (TargetSpeed * PoleClimbComp.Data.ClimbDirectionSign) * DeltaTime;

			if(TargetHeight >= PoleClimbComp.Data.MaxHeight || TargetHeight <= PoleClimbComp.Data.MinHeight)
				TargetSpeed = 0;

			//Clamp our height between max height and slightly above ground so we dont push the player capsule into the floor.
			TargetHeight = Math::Clamp(TargetHeight, PoleClimbComp.Data.MinHeight, PoleClimbComp.Data.MaxHeight);

			//Reset SlipSpeed
			InvoluntarySlipSpeed = 0.0;
		}
		else if (Input.Y < -0.2 || SignedVerticalSpeed < 0.0 || ActivePoleType == EPoleType::Slippery)
		{
			//We are giving input down or have remaining downwards velocity / Climbing on a slippery Pole

			float RelevantInput = Math::Abs(Input.X) < 0.5 && !PoleClimbComp.Data.ActivePole.bAllowFull360Rotation ? -Input.Size() : Input.Y;
			float InputAlpha = Math::GetMappedRangeValueClamped(FVector2D(-PoleClimbComp.Settings.VerticalDeadZone, -1.0),FVector2D(0.0, -1.0), RelevantInput);

			TargetSpeed = (PoleClimbComp.Data.ActivePole.ActorUpVector * PoleClimbComp.Data.ClimbDirectionSign).DotProduct(MoveComp.Velocity);
				
			//Remove any upwards velocity
			if(TargetSpeed > 0.0)
				TargetSpeed = 0.0;

			if(InputAlpha < 0.0)
			{
				//We are giving input so add gravity acceleration while also scaling the gravity based on how our "Down" is aligned with our gravity direction
				float AlignedGravityScalar = (PoleClimbComp.Settings.SlideGravityScalar * Math::Clamp(MoveComp.GravityDirection.DotProduct(-PoleClimbComp.Data.ActivePole.ActorUpVector * PoleClimbComp.Data.ClimbDirectionSign), 0.5, 1));
				TargetSpeed += ((MoveComp.GravityForce * AlignedGravityScalar) * InputAlpha) * DeltaTime;
				TargetSpeed = Math::Max(TargetSpeed, -PoleClimbComp.Settings.TerminalSlideSpeed);
				
				//Reset SlipSpeed
				InvoluntarySlipSpeed = 0.0;

				if(!MoveComp.HasGroundContact())
				{
					bIsSliding = true;
					if(!PoleClimbComp.AnimData.bSliding)
					{
						if(PoleClimbComp.Data.ActivePole.AudioTraceSlideSettings != nullptr)
						{
							Player.ApplySettings(PoleClimbComp.Data.ActivePole.AudioTraceSlideSettings, this, EHazeSettingsPriority::Override);
						}				 	
					}
				}

				if(MoveComp.VerticalSpeed < 0)
				{
					FHazeFrameForceFeedback FF;
					float Alpha = Math::GetMappedRangeValueClamped(FVector2D(0, PoleClimbComp.Settings.TerminalSlideSpeed * 0.5), FVector2D(0, 1), Math::Abs(TargetSpeed));

					FF.LeftMotor = Math::Sin(ActiveDuration * (60 * Alpha)) * (0.25 * Alpha);
					FF.RightMotor = Math::Sin(-ActiveDuration * (60 * Alpha)) * (0.25 * Alpha);
					Player.SetFrameForceFeedback(FF);
				}
			}
			else
			{
				if(ActivePoleType == EPoleType::Slippery)
				{
					float SlipSpeedAcceleration = 0.0; 
                    SlipSpeedAcceleration += -PoleClimbComp.Data.ActivePole.IdleSlideAcceleration * DeltaTime;

					if(PoleClimbComp.Settings.SlideDefaultAmount >= 0)
						TargetSpeed = Math::Min(-PoleClimbComp.Settings.SlideDefaultAmount, TargetSpeed); 

					TargetSpeed += SlipSpeedAcceleration;
					InvoluntarySlipSpeed += SlipSpeedAcceleration;
				}
				else
				{
					//No input so enforce drag on downwards velocity
					float DeceleratedSpeed = TargetSpeed;
					DeceleratedSpeed *= Math::Pow(PoleClimbComp.Settings.SlideNoInputDrag, DeltaTime);

					//Enforce a minimum drag value to ensure we come to a complete halt within a reasonable time frame
					if(Math::Abs(TargetSpeed - DeceleratedSpeed) < PoleClimbComp.Settings.MinimumDragValue)
						TargetSpeed = Math::Min(TargetSpeed + PoleClimbComp.Settings.MinimumDragValue, 0.0);
					else
						TargetSpeed = DeceleratedSpeed;
				}
			}

			TargetHeight += (TargetSpeed * PoleClimbComp.Data.ClimbDirectionSign) * DeltaTime;

			if(PoleClimbComp.Data.ActivePole.bAllowSlidingOff &&
				 ((PoleClimbComp.Data.ClimbDirectionSign > 0 && TargetHeight < PoleClimbComp.Data.MinHeight) ||
				 	(PoleClimbComp.Data.ClimbDirectionSign < 0 && TargetHeight > PoleClimbComp.Data.MaxHeight)))
			{
				if(PoleClimbComp.Data.ActivePole.PoleType == EPoleType::Slippery || Input.Y < 0)
					bWillSlidePastEndPoint = true;
			}

			//Clamp our height between max height and slightly above ground so we dont push the player capsule into the floor.
			TargetHeight = Math::Clamp(TargetHeight, PoleClimbComp.Data.MinHeight, PoleClimbComp.Data.MaxHeight);
		}
		else
		{
			//We stopped giving input / did not have downwards velocity to drag / pole is not slippery = cancel out velocity
			TargetSpeed = 0.0;
		}

		if(PoleClimbComp.AnimData.bSliding && !bIsSliding)
		{
			Player.ClearSettingsWithAsset(PoleClimbComp.Data.ActivePole.AudioTraceSlideSettings, this);
		}

		PoleClimbComp.AnimData.bSliding = bIsSliding;
		SyncedTargetSpeedForAnimation.Value = TargetSpeed;

		if(IsDebugActive())
		{
			PrintToScreenScaled("TargetVerticalSpeed: " + TargetSpeed, Color = FLinearColor::Yellow, Scale = 2.0);
			PrintToScreenScaled("SlipSpeed: " + InvoluntarySlipSpeed, Color = FLinearColor::LucBlue, Scale = 2.0);
			PrintToScreen("Current/Min/Max: " + PoleClimbComp.Data.CurrentHeight + " / " + PoleClimbComp.Data.MinHeight + " / " + PoleClimbComp.Data.MaxHeight);
		}
	}

	//Perform translation / rotation along pole
	void HandleMovement(float DeltaTime, FVector2D Input)
	{
		if (PoleClimbComp.Data.ActivePole.bAllowFull360Rotation && PerspectiveModeComp.IsIn3DPerspective() && PoleClimbComp.Data.ActivePole.bAllowAnyRotation)
		{
			if (PoleClimbComp.Data.ActivePole.bFaceBackTowardsInputDirection)
			{
				FVector DirToPlayer = PoleClimbComp.GetPoleToPlayerVector();
				TargetRot = FRotator::MakeFromX(-DirToPlayer);
				FVector CameraRight = Player.ViewRotation.RightVector * Math::Sign(Input.X);
				FVector WantedDirToPlayer = CameraRight.VectorPlaneProject(PoleClimbComp.Data.ActivePole.ActorUpVector).GetSafeNormal();
				if (MoveComp.MovementInput.Size() < PoleClimbComp.Settings.VerticalDeadZone)
				{
					// if (PoleClimb::bRememberWantedDirectionWhenLosingInput && !LastWantedMovementDirection.IsNearlyZero())
					// 	WantedDirToPlayer = LastWantedMovementDirection;
					// else
						WantedDirToPlayer = DirToPlayer;
				}
				else
				{
					LastWantedMovementDirection = WantedDirToPlayer;
				}
				
				if (DirToPlayer.Equals(WantedDirToPlayer, 0.01))
				{
					TargetRot = FRotator::MakeFromX(-WantedDirToPlayer);
					AcceleratedRotationSpeed.SnapTo(0);
				}
				else
				{
					float TargetRotationVelocity = PoleClimbComp.Settings.MaxRotationSpeed;
					AcceleratedRotationSpeed.AccelerateTo(TargetRotationVelocity, 0.35, DeltaTime);
				}

				if(Math::Abs(Input.Y) < PoleClimbComp.Settings.VerticalDeadZone)
					TargetRot = Math::RInterpConstantTo(
						FRotator::MakeFromX(-DirToPlayer),
						FRotator::MakeFromX(-WantedDirToPlayer),
						DeltaTime, AcceleratedRotationSpeed.Value);
			}
			else
			{
				float TargetRotationVelocity = PoleClimbComp.Settings.MaxRotationSpeed * -Input.X * PoleClimbComp.Data.ClimbDirectionSign;

				//Enforce a minimum rotational velocity if giving stick input.
				if(Math::Abs(TargetRotationVelocity) <= PoleClimbComp.Settings.MinimumRotationSpeed)
					TargetRotationVelocity = Math::Sign(TargetRotationVelocity) * PoleClimbComp.Settings.MinimumRotationSpeed;
				
				AcceleratedRotationSpeed.AccelerateTo(TargetRotationVelocity, 0.35, DeltaTime);
				FVector DirToPlayer = PoleClimbComp.GetPoleToPlayerVector();

				FVector NewDir = DirToPlayer.RotateAngleAxis(AcceleratedRotationSpeed.Value * DeltaTime, PoleClimbComp.Data.ActivePole.ActorUpVector);
				TargetRot = (NewDir * -1.0).Rotation();

				TargetRot = FRotator::MakeFromXZ(TargetRot.ForwardVector, PoleClimbComp.Data.ActivePole.ActorUpVector * PoleClimbComp.Data.ClimbDirectionSign);
			}
		}
		else if (PoleClimbComp.Data.bPerformingTurnaround)
		{
			TargetRot = PoleClimbComp.Data.TurnAroundRotation;
		}
		else
		{
			// We're not performing a turnaround, so lerp to the rotation we want instead
			FVector DirToPlayer = PoleClimbComp.GetPoleToPlayerVector();
			FVector WantedDirToPlayer = PoleClimbComp.GetClosestPoleAllowedDirection(DirToPlayer);
			if (!PoleClimbComp.Data.ActivePole.bAllowAnyRotation)
				WantedDirToPlayer = PoleClimbComp.Data.ActivePole.ActorForwardVector;

			if (DirToPlayer.Equals(WantedDirToPlayer, 0.01))
			{
				TargetRot = FRotator::MakeFromXZ(-WantedDirToPlayer, MoveComp.WorldUp);
				AcceleratedRotationSpeed.SnapTo(0);
			}
			else
			{
				float TargetRotationVelocity = PoleClimbComp.Settings.MaxRotationSpeed;
				AcceleratedRotationSpeed.AccelerateTo(TargetRotationVelocity, 0.35, DeltaTime);
			}

			TargetRot = Math::RInterpConstantTo(
				FRotator::MakeFromXZ(-DirToPlayer, MoveComp.WorldUp),
				FRotator::MakeFromXZ(-WantedDirToPlayer, MoveComp.WorldUp),
				DeltaTime, AcceleratedRotationSpeed.Value);
		}

		// Always constrain target rotation to pole's actor up, otherwise capsule rotation will be weird on tilted poles.
		FVector UpVector = PoleClimbComp.Data.ActivePole.ActorUpVector;
		if(UpVector.DotProduct(MoveComp.WorldUp) < 0.0)
			UpVector = -UpVector;
		TargetRot = FRotator::MakeFromXZ(TargetRot.ForwardVector.VectorPlaneProject(PoleClimbComp.Data.ActivePole.ActorUpVector), UpVector);
	
		TargetLocation = PoleClimbComp.Data.ActivePole.ActorLocation;
		TargetLocation += PoleClimbComp.Data.ActivePole.ActorUpVector * TargetHeight;
		TargetLocation += -TargetRot.ForwardVector * PoleClimbComp.Settings.PlayerPoleHorizontalOffset;
		FVector DeltaMove = TargetLocation - Player.ActorLocation;

		Movement.AddDelta(DeltaMove);
		Movement.SetRotation(TargetRot);
		Movement.IgnoreSplineLockConstraint();
		MoveComp.ApplyMove(Movement);

		if((!MoveComp.HasCeilingContact() && !MoveComp.HasGroundContact()) || (MoveComp.HasCeilingContact() && TargetSpeed < 0) || (MoveComp.HasGroundContact() && TargetSpeed > 0))
		{
			PoleClimbComp.Data.CurrentHeight = TargetHeight;
		}
		else
		{
			TargetSpeed = 0;
			SyncedTargetSpeedForAnimation.Value = 0.0;
		}

		if(MoveComp.HasWallContact())
			AcceleratedRotationSpeed.SnapTo(0);
	}

	void SetAnimationData(FVector2D MoveInput)
	{
		PoleClimbComp.AnimData.PoleClimbVerticalVelocity = TargetSpeed;
		PoleClimbComp.AnimData.PoleClimbVerticalInput = ((!PoleClimbComp.Data.ActivePole.bAllowClimbingUp && PoleClimbComp.Data.ActivePole.PoleType == EPoleType::Slippery) || TargetSpeed == 0) ? 0 : MoveInput.Y * MoveComp.WorldUp.DotProduct(Player.ViewRotation.UpVector);

		if((PoleClimbComp.Data.ClimbDirectionSign == 1 && PoleClimbComp.AnimData.PoleClimbVerticalInput < 0 && PoleClimbComp.Data.CurrentHeight <= PoleClimbComp.Data.MinHeight)
			||(PoleClimbComp.Data.ClimbDirectionSign == -1 && (PoleClimbComp.AnimData.PoleClimbVerticalInput < 0 && PoleClimbComp.Data.CurrentHeight >= PoleClimbComp.Data.MaxHeight)))
		{
			//Stop BS animation if we are at the bottom
			PoleClimbComp.AnimData.PoleClimbVerticalInput = 0;
		}

		PoleClimbComp.AnimData.PoleRotationSpeed = AcceleratedRotationSpeed.Value * PoleClimbComp.Data.ClimbDirectionSign;

		if (!PoleClimbComp.Data.ActivePole.bAllowFull360Rotation)
			PoleClimbComp.AnimData.PoleRotationInput = Math::Clamp(AcceleratedRotationSpeed.Value / -PoleClimbComp.Settings.MaxRotationSpeed, -1.0, 1.0);
		else
			PoleClimbComp.AnimData.PoleRotationInput = MoveInput.X;

		PoleClimbComp.AnimData.SlipVelocity = InvoluntarySlipSpeed;
	}

	void HandleRemoteMovement()
	{
		Movement.ApplyCrumbSyncedAirMovement();

		FHazeSyncedActorPosition SyncedActorData = MoveComp.GetCrumbSyncedPosition();

		// Always constrain target rotation to pole's actor up, otherwise capsule rotation will be weird on tilted poles.
		FRotator Rotation;
		if(PoleClimbComp.Data.ActivePole != nullptr)
		{
			FVector UpVector = PoleClimbComp.Data.ActivePole.ActorUpVector;
			if(UpVector.DotProduct(MoveComp.WorldUp) < 0.0)
				UpVector = -UpVector;
			Rotation = FRotator::MakeFromXZ(SyncedActorData.WorldRotation.ForwardVector.VectorPlaneProject(PoleClimbComp.Data.ActivePole.ActorUpVector), UpVector);
		}
		else
			Rotation = Player.ActorRotation;

		Movement.SetRotation(Rotation);
		MoveComp.ApplyMove(Movement);
	}

	void SetRemoteAnimationData(float DeltaTime)
	{
		FHazeSyncedActorPosition SyncedPosition = MoveComp.GetCrumbSyncedPosition();

		// This isn't correct in cases where the pole is moving/swaying slightly
		//float VerticalSpeed = SyncedPosition.WorldVelocity.DotProduct(MoveComp.WorldUp);
		float VerticalSpeed = SyncedTargetSpeedForAnimation.Value;

		if (PoleClimbComp.Data.ActivePole == nullptr)
			return;

		PoleClimbComp.AnimData.SlipVelocity = InvoluntarySlipSpeed;
		PoleClimbComp.AnimData.PoleClimbVerticalVelocity = VerticalSpeed;
		PoleClimbComp.AnimData.PoleClimbVerticalInput = Math::Clamp(VerticalSpeed / PoleClimbComp.Settings.ClimbSpeed, -1.0, 1.0);
		PoleClimbComp.AnimData.PoleClimbVerticalInput = ((!PoleClimbComp.Data.ActivePole.bAllowClimbingUp && PoleClimbComp.Data.ActivePole.PoleType == EPoleType::Slippery) || SyncedTargetSpeedForAnimation.Value == 0)? 0 : PoleClimbComp.AnimData.PoleClimbVerticalInput;

		FVector PrevDirToPlayer = PoleClimbComp.GetPoleToPlayerVector();

		FVector NewDirToPlayer = SyncedPosition.WorldLocation - PoleClimbComp.Data.ActivePole.ActorLocation;
		NewDirToPlayer = NewDirToPlayer.ConstrainToPlane(PoleClimbComp.Data.ActivePole.ActorUpVector);
		NewDirToPlayer = NewDirToPlayer.GetSafeNormal();

		FQuat MadeRotation = FQuat::FindBetweenNormals(PrevDirToPlayer, NewDirToPlayer);

		float TargetRotationVelocity = Math::RadiansToDegrees(MadeRotation.GetTwistAngle(PoleClimbComp.Data.ActivePole.ActorUpVector)) / DeltaTime;
		AcceleratedRotationSpeed.AccelerateTo(TargetRotationVelocity, 0.35, DeltaTime);

		PoleClimbComp.AnimData.PoleRotationSpeed = AcceleratedRotationSpeed.Value;
		PoleClimbComp.AnimData.PoleRotationInput = Math::Clamp(AcceleratedRotationSpeed.Value / -PoleClimbComp.Settings.MaxRotationSpeed, -1.0, 1.0);
	}

	void ClampInputWithinDeadZones(FVector2D& Input)
	{
		if(Input.Y > -PoleClimbComp.Settings.VerticalDeadZone && Input.Y < PoleClimbComp.Settings.VerticalDeadZone)
			Input.Y = 0.0;

		if(Input.X > -PoleClimbComp.Settings.VerticalDeadZone && Input.X < PoleClimbComp.Settings.VerticalDeadZone)
			Input.X = 0.0;
	}
};

struct FPlayerPoleClimbDeactivationParams
{
	EPlayerPoleClimbDeactivationType DeactivationType = EPlayerPoleClimbDeactivationType::None; 
}

enum EPlayerPoleClimbDeactivationType
{
	None,
	Disabled,
	Transition,
	Interrupted,
	ReachedBottom,
	LostSplineLock,
	StopOnImpact,
	OutsideValidHeight
}