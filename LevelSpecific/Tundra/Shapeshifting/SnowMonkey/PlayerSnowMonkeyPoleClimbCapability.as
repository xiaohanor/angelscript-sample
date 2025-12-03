// OL: SNOW MONKEY USES PLAYER POLE CLIMB MOVEMENT INSTEAD, BELOW CAPABILITY KEPT TEMPORARILY INCASE STUFF BREAKS
// class UTundraPlayerSnowMonkeyPoleClimbCapability : UHazePlayerCapability
// {
// 	default CapabilityTags.Add(CapabilityTags::Movement);
// 	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
// 	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
// 	default CapabilityTags.Add(PlayerMovementTags::PoleClimb);

// 	default DebugCategory = n"Movement";
	
// 	default TickGroup = EHazeTickGroup::ActionMovement;
// 	default TickGroupOrder = 25;
// 	default TickGroupSubPlacement = 1;

// 	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

// 	UPlayerMovementComponent MoveComp;
// 	UPlayerPoleClimbComponent PoleClimbComp;

// 	float TargetSpeed;

// 	//If set to slippery then this is how much of our current speed is involuntary
// 	float InvoluntarySlipSpeed;

// 	FVector TargetLocation;
// 	FRotator TargetRot;

// 	USimpleMovementData Movement;
// 	FHazeAcceleratedFloat AcceleratedRotationSpeed;

// 	//Current Velocity will drop us off the bottom of the pole
// 	bool bWillSlidePastEndPoint = false;

// 	/*
// 	 * TODO[AL]:
// 	 * - Remap horizontal input to range from 0-1 within deadzone / full input range similar to Y Input
// 	 * - Enter needs an input check and maybe a longer cooldown? (Sliding off bottom and not giving input reattaches after .25s)
// 	 */

// 	UFUNCTION(BlueprintOverride)
// 	void Setup()
// 	{
// 		MoveComp = UPlayerMovementComponent::Get(Player);
// 		Movement = MoveComp.SetupSimpleMovementData();
// 		PoleClimbComp = UPlayerPoleClimbComponent::GetOrCreate(Player);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldActivate() const
// 	{
// 		if (MoveComp.HasMovedThisFrame())
//         	return false;

// 		if (PoleClimbComp.GetState() == EPlayerPoleClimbState::Climbing)
// 			return true;
			
// 		return false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldDeactivate(FPlayerPoleClimbDeactivationParams& Params) const
// 	{
// 		if (MoveComp.HasMovedThisFrame())
// 		{
// 			if(PoleClimbComp.GetState() == EPlayerPoleClimbState::Climbing)
// 			{
// 				//Internal state was not altered, a different move took over
// 				Params.DeactivationType = EPlayerPoleClimbDeactivationType::Interrupted;
// 			}
// 			else
// 			{
// 				//Internal state was altered, we transitioned to a different PoleClimb Move
// 				Params.DeactivationType = EPlayerPoleClimbDeactivationType::Transition;
// 			}

// 			return true;
// 		}

// 		if(!IsValid(PoleClimbComp.Data.ActivePole))
// 		{
// 			Params.DeactivationType = EPlayerPoleClimbDeactivationType::Disabled;
// 			return true;
// 		}

// 		if(!PoleClimbComp.Data.ActivePole.bEnabled)
// 		{
// 			Params.DeactivationType = EPlayerPoleClimbDeactivationType::Disabled;
// 			return true;
// 		}	

// 		if(!Player.IsSelectedBy(PoleClimbComp.Data.ActivePole.UsableByPlayers))
// 		{
// 			Params.DeactivationType = EPlayerPoleClimbDeactivationType::Disabled;
// 			return true;
// 		}	

// 		if (PoleClimbComp.GetState() != EPlayerPoleClimbState::Climbing)
// 		{
// 			Params.DeactivationType = EPlayerPoleClimbDeactivationType::Transition;
// 			return true;
// 		}

// 		if(bWillSlidePastEndPoint)
// 		{
// 			Params.DeactivationType = EPlayerPoleClimbDeactivationType::ReachedBottom;
// 			return true;
// 		}

// 		return false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated()
// 	{
// 		Player.BlockCapabilities(BlockedWhileIn::PoleClimb, this);

// 		// If we came from JumpUp then set our velocity to be in motion
// 		if(PoleClimbComp.GetState() == EPlayerPoleClimbState::Dash)
// 			Player.SetActorVerticalVelocity(MoveComp.VerticalVelocity);

// 		AcceleratedRotationSpeed.SnapTo(0.0, 0.0);
// 		InvoluntarySlipSpeed = 0.0;
// 		TargetSpeed = 0.0;

// 		PoleClimbComp.SetState(EPlayerPoleClimbState::Climbing);

// 		//Reset Various moves that we could chain into from Poleclimb once enter is performed.
// 		Player.ResetWallScrambleUsage();
// 		Player.ResetAirJumpUsage();
// 		Player.ResetAirDashUsage();
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FPlayerPoleClimbDeactivationParams Params)
// 	{
// 		Player.UnblockCapabilities(BlockedWhileIn::PoleClimb, this);

// 		AcceleratedRotationSpeed.SnapTo(0.0, 0.0);
// 		bWillSlidePastEndPoint = false;

// 		switch(Params.DeactivationType)
// 		{
// 			case EPlayerPoleClimbDeactivationType::Transition:
// 			break;

// 			default:
// 				PoleClimbComp.StopClimbing();
// 			break;
// 		}
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		if(MoveComp.PrepareMove(Movement))
// 		{
// 			if(HasControl())
// 			{	
// 				FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
// 				ClampInputWithinDeadZones(MoveInput);

// 				CalculateHeightAndVelocity(DeltaTime, MoveInput);
// 				HandleMovement(DeltaTime, MoveInput);
// 				SetAnimationData(MoveInput);
// 			}
// 			else
// 			{
// 				SetRemoteAnimationData(DeltaTime);
// 				HandleRemoteMovement();
// 			}
// 		}

// 		Player.Mesh.RequestLocomotion(n"PoleClimb", this);
// 	}

// 	//Calculate our current clamped height / translation / Velocity along the pole
// 	void CalculateHeightAndVelocity(float DeltaTime, FVector2D Input)
// 	{
// 		float SignedVerticalSpeed = MoveComp.WorldUp.DotProduct(MoveComp.VerticalVelocity);

// 		if(Input.Y > 0.0 && (PoleClimbComp.Data.ActivePole.PoleType == EPoleType::Default || PoleClimbComp.Data.ActivePole.bAllowClimbingUp))
// 		{
// 			//We are climbing upwards

// 			float InputAlpha = Math::GetMappedRangeValueClamped(FVector2D(PoleClimbComp.Settings.VerticalDeadZone, 1.0),FVector2D(0.0, 1.0), Input.Y);

// 			float TargetVerticalSpeed = PoleClimbComp.Settings.ClimbSpeed * InputAlpha;
			
// 			//Enforce a minimum vertical velocity if giving stick input.
// 			if(Math::Abs(TargetVerticalSpeed) <= PoleClimbComp.Settings.MinimumVerticalSpeed)
// 				TargetVerticalSpeed = Math::Sign(TargetVerticalSpeed) * PoleClimbComp.Settings.MinimumVerticalSpeed;

// 			TargetSpeed = Math::FInterpConstantTo(SignedVerticalSpeed, TargetVerticalSpeed, DeltaTime, SignedVerticalSpeed > 0 ? PoleClimbComp.Settings.ClimbInterpSpeed : PoleClimbComp.Settings.SlideBrakeInterpSpeed);
			
// 			PoleClimbComp.Data.CurrentHeight += (TargetSpeed * PoleClimbComp.Data.ClimbDirectionSign) * DeltaTime;

// 			//Clamp our height between max height and slightly above ground so we dont push the player capsule into the floor.
// 			PoleClimbComp.Data.CurrentHeight = Math::Clamp(PoleClimbComp.Data.CurrentHeight, PoleClimbComp.Data.MinHeight, PoleClimbComp.Data.MaxHeight);

// 			//Reset SlipSpeed
// 			InvoluntarySlipSpeed = 0.0;
// 		}
// 		else if (Input.Y < 0.0 || SignedVerticalSpeed < 0.0 || PoleClimbComp.Data.ActivePole.PoleType == EPoleType::Slippery)
// 		{
// 			//We are giving input down or have remaining downwards velocity / Climbing on a slippery Pole

// 			float InputAlpha = Math::GetMappedRangeValueClamped(FVector2D(-PoleClimbComp.Settings.VerticalDeadZone, -1.0),FVector2D(0.0, -1.0), Input.Y);

// 			if(InputAlpha < 0.0)
// 			{
// 				//We are giving input so add gravity acceleration
// 				TargetSpeed = MoveComp.WorldUp.DotProduct(MoveComp.VerticalVelocity);
// 				TargetSpeed += ((MoveComp.GravityForce * PoleClimbComp.Settings.SlideGravityScalar) * InputAlpha) * DeltaTime;

// 				TargetSpeed = Math::Max(TargetSpeed, -PoleClimbComp.Settings.TerminalSlideSpeed);
				
// 				//Reset SlipSpeed
// 				InvoluntarySlipSpeed = 0.0;
// 			}
// 			else
// 			{
// 				//Remove any upwards speed to make sure we dont slide upwards (Needed?)
// 				if(TargetSpeed > 0.0)
// 					TargetSpeed = 0.0;

// 				if(PoleClimbComp.Data.ActivePole.PoleType == EPoleType::Slippery)
// 				{
// 					float SlipSpeedAcceleration = 0.0; 
// 					SlipSpeedAcceleration += -PoleClimbComp.Data.ActivePole.IdleSlideAcceleration * DeltaTime;
					
// 					TargetSpeed += SlipSpeedAcceleration;
// 					InvoluntarySlipSpeed += SlipSpeedAcceleration;
// 				}
// 				else
// 				{
// 					//No input so enforce drag on downwards velocity
// 					float DeceleratedSpeed = TargetSpeed;
// 					DeceleratedSpeed *= Math::Pow(PoleClimbComp.Settings.SlideNoInputDrag, DeltaTime);

// 					//Enforce a minimum drag value to ensure we come to a complete halt within a reasonable time frame
// 					if(Math::Abs(TargetSpeed - DeceleratedSpeed) < PoleClimbComp.Settings.MinimumDragValue)
// 						TargetSpeed = Math::Min(TargetSpeed + PoleClimbComp.Settings.MinimumDragValue, 0.0);
// 					else
// 						TargetSpeed = DeceleratedSpeed;
// 				}
// 			}

// 			PoleClimbComp.Data.CurrentHeight += (TargetSpeed * PoleClimbComp.Data.ClimbDirectionSign) * DeltaTime;

// 			if(PoleClimbComp.Data.ActivePole.bAllowSlidingOff &&
// 				 ((PoleClimbComp.Data.ClimbDirectionSign > 0 && PoleClimbComp.Data.CurrentHeight < PoleClimbComp.Data.MinHeight) ||
// 				 	(PoleClimbComp.Data.ClimbDirectionSign < 0 && PoleClimbComp.Data.CurrentHeight > PoleClimbComp.Data.MaxHeight)))
// 			{
// 				bWillSlidePastEndPoint = true;
// 			}
// 			else
// 			{
// 				//Clamp our height between max height and slightly above ground so we dont push the player capsule into the floor.
// 				PoleClimbComp.Data.CurrentHeight = Math::Clamp(PoleClimbComp.Data.CurrentHeight, PoleClimbComp.Data.MinHeight, PoleClimbComp.Data.MaxHeight);
// 			}
// 		}
// 		else
// 		{
// 			//We stopped giving input / did not have downwards velocity to drag / pole is not slippery = cancel out velocity
// 			TargetSpeed = 0.0;
// 		}

// 		if(IsDebugActive())
// 		{
// 			PrintToScreenScaled("PoleClimbVelocity: " + TargetSpeed, Color = FLinearColor::Yellow, Scale = 2.0);
// 			PrintToScreenScaled("SlipSpeed: " + InvoluntarySlipSpeed, Color = FLinearColor::LucBlue, Scale = 2.0);
// 			PrintToScreen("Current/Min/Max: " + PoleClimbComp.Data.CurrentHeight + " / " + PoleClimbComp.Data.MinHeight + " / " + PoleClimbComp.Data.MaxHeight);
// 		}
// 	}

// 	//Perform translation / rotation along pole
// 	void HandleMovement(float DeltaTime, FVector2D Input)
// 	{
// 		float TargetRotationVelocity = PoleClimbComp.Settings.MaxRotationSpeed * -Input.X;

// 		//Enforce a minimum rotational velocity if giving stick input.
// 		if(Math::Abs(TargetRotationVelocity) <= PoleClimbComp.Settings.MinimumRotationSpeed)
// 			TargetRotationVelocity = Math::Sign(TargetRotationVelocity) * PoleClimbComp.Settings.MinimumRotationSpeed;
		
// 		AcceleratedRotationSpeed.AccelerateTo(TargetRotationVelocity, 0.35, DeltaTime);
// 		FVector DirToPlayer = PoleClimbComp.GetPoleToPlayerVector();
// 		FVector NewDir = DirToPlayer.RotateAngleAxis(AcceleratedRotationSpeed.Value * DeltaTime, MoveComp.WorldUp);
// 		TargetRot = (NewDir * -1.0).Rotation();

// 		TargetLocation = PoleClimbComp.Data.ActivePole.ActorLocation;
// 		TargetLocation += PoleClimbComp.Data.ActivePole.ActorUpVector * PoleClimbComp.Data.CurrentHeight;
// 		TargetLocation += NewDir * PoleClimbComp.Settings.PlayerPoleHorizontalOffset;
// 		FVector DeltaMove = TargetLocation - Player.ActorLocation;

// 		Movement.AddDelta(DeltaMove);
// 		Movement.SetRotation(TargetRot);
// 		MoveComp.ApplyMove(Movement);
// 	}

// 	void SetAnimationData(FVector2D MoveInput)
// 	{
// 		PoleClimbComp.AnimData.PoleClimbVerticalVelocity = TargetSpeed;
// 		PoleClimbComp.AnimData.PoleClimbVerticalInput = MoveInput.Y;

// 		PoleClimbComp.AnimData.PoleRotationSpeed = AcceleratedRotationSpeed.Value;
// 		PoleClimbComp.AnimData.PoleRotationInput = MoveInput.X;

// 		PoleClimbComp.AnimData.SlipVelocity = InvoluntarySlipSpeed;
// 	}

// 	void HandleRemoteMovement()
// 	{
// 		Movement.ApplyCrumbSyncedAirMovement();
// 		MoveComp.ApplyMove(Movement);
// 	}

// 	void SetRemoteAnimationData(float DeltaTime)
// 	{
// 		FHazeSyncedActorPosition SyncedPosition = MoveComp.GetCrumbSyncedPosition();

// 		float VerticalSpeed = SyncedPosition.WorldVelocity.DotProduct(MoveComp.WorldUp);

// 		PoleClimbComp.AnimData.SlipVelocity = InvoluntarySlipSpeed;

// 		PoleClimbComp.AnimData.PoleClimbVerticalVelocity = VerticalSpeed;
// 		PoleClimbComp.AnimData.PoleClimbVerticalInput = Math::Clamp(VerticalSpeed / PoleClimbComp.Settings.ClimbSpeed, -1.0, 1.0);

// 		FVector PrevDirToPlayer = PoleClimbComp.GetPoleToPlayerVector();

// 		FVector NewDirToPlayer = SyncedPosition.WorldLocation - PoleClimbComp.Data.ActivePole.ActorLocation;
// 		NewDirToPlayer = NewDirToPlayer.ConstrainToPlane(PoleClimbComp.Data.ActivePole.ActorUpVector);
// 		NewDirToPlayer = NewDirToPlayer.GetSafeNormal();

// 		FQuat MadeRotation = FQuat::FindBetweenNormals(PrevDirToPlayer, NewDirToPlayer);

// 		float TargetRotationVelocity = Math::RadiansToDegrees(MadeRotation.GetTwistAngle(PoleClimbComp.Data.ActivePole.ActorUpVector)) / DeltaTime;
// 		AcceleratedRotationSpeed.AccelerateTo(TargetRotationVelocity, 0.35, DeltaTime);

// 		PoleClimbComp.AnimData.PoleRotationSpeed = AcceleratedRotationSpeed.Value;
// 		PoleClimbComp.AnimData.PoleRotationInput = Math::Clamp(AcceleratedRotationSpeed.Value / -PoleClimbComp.Settings.MaxRotationSpeed, -1.0, 1.0);
// 	}

// 	void ClampInputWithinDeadZones(FVector2D& Input)
// 	{
// 		if(Input.Y > -PoleClimbComp.Settings.VerticalDeadZone && Input.Y < PoleClimbComp.Settings.VerticalDeadZone)
// 			Input.Y = 0.0;

// 		if(Input.X > -PoleClimbComp.Settings.VerticalDeadZone && Input.X < PoleClimbComp.Settings.VerticalDeadZone)
// 			Input.X = 0.0;
// 	}
// };