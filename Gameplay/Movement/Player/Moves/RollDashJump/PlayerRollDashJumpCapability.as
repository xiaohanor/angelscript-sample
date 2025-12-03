class UPlayerRollDashJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::Dash);
	default CapabilityTags.Add(PlayerMovementTags::RollDash);
	default CapabilityTags.Add(PlayerMovementTags::Jump);

	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);
	default CapabilityTags.Add(BlockedWhileIn::Slide);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 45;
	default TickGroupSubPlacement = 1;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerRollDashComponent RollDashComp;
	UPlayerJumpComponent JumpComp;
	UPlayerAirMotionComponent AirMotionComp;
	UPlayerSprintComponent SprintComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UHazeInputComponent InputComp;

	FVector TargetVerticalVelocity;
	FVector ImpulseHorizontalVelocity;
	FVector InitialDirection;

	bool bHasCalculatedLaunchVelocities = false;
	private bool bDoneAccelerating = false;

	bool bJumpStartBlockActive = false;
	private const float DURATION_BLOCK_JUMPSTART = 0.45;

	//
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RollDashComp = UPlayerRollDashComponent::Get(Player);
		JumpComp = UPlayerJumpComponent::Get(Player);
		AirMotionComp = UPlayerAirMotionComponent::Get(Player);
		SprintComp = UPlayerSprintComponent::Get(Player);
		InputComp = UHazeInputComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
#if !RELEASE
		if(!IsDebugActive())
			return;

		if (Time::GetGameTimeSince(RollDashComp.GetLastRollDashActivation()) <= RollDashComp.Settings.MaxAvailableTimeAfterRoll
			&& Time::GetGameTimeSince(RollDashComp.GetLastRollDashActivation()) >= RollDashComp.Settings.TimeBeforeRollDashJumpAvailable)
			{
				Debug::DrawDebugString(Player.ActorCenterLocation, "DashJump Available");
			}
#endif
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!MoveComp.IsOnWalkableGround() && !JumpComp.IsInJumpGracePeriod())
			return false;
		
		if (Time::GetGameTimeSince(RollDashComp.GetLastRollDashActivation()) <= RollDashComp.Settings.MaxAvailableTimeAfterRoll
			&& Time::GetGameTimeSince(RollDashComp.GetLastRollDashActivation()) >= RollDashComp.Settings.TimeBeforeRollDashJumpAvailable)
			{
				if(WasActionStartedDuringTime(ActionNames::MovementJump, JumpComp.Settings.InputBufferWindow))
				{
					return true;
				}
			}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (MoveComp.HasGroundContact() && bDoneAccelerating)
			return true;

		if (MoveComp.HasCeilingContact())
			return true;

		if (MoveComp.HasImpulse())
			return true;
		
		if ((MoveComp.IsInAir() && MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp) < -KINDA_SMALL_NUMBER) && bDoneAccelerating)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Jump, this);
		Player.BlockCapabilities(BlockedWhileIn::RollDashJumpStart, this);
		bJumpStartBlockActive = true;
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);
		JumpComp.StopJumpGracePeriod();
		JumpComp.ConsumeBufferedJump();

		UPlayerAirMotionSettings::GetSettings(Player).DragOfExtraHorizontalVelocity = 500;

		InitialDirection = MoveComp.HorizontalVelocity.GetSafeNormal();

		TargetVerticalVelocity = MoveComp.WorldUp * (JumpComp.Settings.Impulse * RollDashComp.Settings.VerticalVelocityMultiplier);
		ImpulseHorizontalVelocity = MoveComp.HorizontalVelocity.GetSafeNormal() 
			* Math::Max(RollDashComp.Settings.PeakHorizontalVelocity,
				MoveComp.HorizontalVelocity.Size());

		RollDashComp.bTriggeredRollDashJump = true;
		bDoneAccelerating = false;
		bHasCalculatedLaunchVelocities = false;

		if(RollDashComp.Settings.RollDashJumpAnticipationDuration == 0)
		{
			GetGroundAlignedAdjustedVelocity(ImpulseHorizontalVelocity, TargetVerticalVelocity);
			Player.SetActorHorizontalAndVerticalVelocity(ImpulseHorizontalVelocity, TargetVerticalVelocity);
			
			TriggerLaunchEffects();
		}
		else
		{
			//Force Feedback / Controller effects
			switch(InputComp.ControllerType)
			{
				case EHazePlayerControllerType::Xbox:
				if(RollDashComp.RollDashJumpFF != nullptr)
					Player.PlayForceFeedback(RollDashComp.RollDashJumpFF, false, false, this);
				break;
				
				case EHazePlayerControllerType::PS4:
				case EHazePlayerControllerType::PS5:
					Player.PlayForceFeedback(RollDashComp.RollDashJumpFF, false, false, this);
					// Player.ApplyGamepadLightColor(FColor::Purple, this);
				break;

				case EHazePlayerControllerType::Keyboard:
				break;

				case EHazePlayerControllerType::Sage_Pro:
				case EHazePlayerControllerType::Sage_DualJoycon:
				case EHazePlayerControllerType::Sage_Handheld:
				break;

				default:
				break;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Jump, this);

		if(bJumpStartBlockActive)
			Player.UnblockCapabilities(BlockedWhileIn::RollDashJumpStart, this);

		RollDashComp.bTriggeredRollDashJump = false;
		bJumpStartBlockActive = false;

		UPlayerAirMotionSettings::ClearDragOfExtraHorizontalVelocity(Player, this);

		switch(InputComp.ControllerType)
		{
			case EHazePlayerControllerType::Xbox:
			break;
			
			case EHazePlayerControllerType::PS4:
			case EHazePlayerControllerType::PS5:
				// Player.ClearGamepadLightColor(this);
			break;

			case EHazePlayerControllerType::Keyboard:
			break;

			case EHazePlayerControllerType::Sage_Pro:
			case EHazePlayerControllerType::Sage_DualJoycon:
			case EHazePlayerControllerType::Sage_Handheld:
			break;

			default:
			break;
		}

		UPlayerCoreMovementEffectHandler::Trigger_RollDashJumpCancelledOrReachedApex(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(ActiveDuration >= DURATION_BLOCK_JUMPSTART && bJumpStartBlockActive)
			{
				Player.UnblockCapabilities(BlockedWhileIn::RollDashJumpStart, this);
				bJumpStartBlockActive = false;
			}

			if(HasControl())
			{
				//If we finished the anticipation part or had an anticipation time of 0
				//Handle Air motion
				if((RollDashComp.Settings.RollDashJumpAnticipationDuration > 0 && bDoneAccelerating)|| RollDashComp.Settings.RollDashJumpAnticipationDuration == 0)
				{
					//Handle our air velocity
					FVector AirControlVelocity = AirMotionComp.CalculateStandardAirControlVelocity(
						MoveComp.MovementInput,
						MoveComp.HorizontalVelocity,
						DeltaTime,
						AirMovementSpeedMultiplier = 1.0
					);

					Movement.AddHorizontalVelocity(AirControlVelocity);
					Movement.AddOwnerVerticalVelocity();

					Movement.AddGravityAcceleration();
					Movement.InterpRotationToTargetFacingRotation(JumpComp.Settings.FacingDirectionInterpSpeed * MoveComp.MovementInput.Size());

					Movement.RequestFallingForThisFrame();
				}
				else
				{
					//If we finished our windup / Anticipation then add our velocity (Launch the player)
					if(ActiveDuration >= RollDashComp.Settings.RollDashJumpAnticipationDuration)
					{
						if(!bHasCalculatedLaunchVelocities)
						{
							GetGroundAlignedAdjustedVelocity(ImpulseHorizontalVelocity, TargetVerticalVelocity);
							bHasCalculatedLaunchVelocities = true;
						}
						float Alpha = Math::Clamp((ActiveDuration - RollDashComp.Settings.RollDashJumpAnticipationDuration) / RollDashComp.Settings.AccelerationDuration, 0, 1);

						FVector TargetVertical = MoveComp.WorldUp * Math::Lerp(0, TargetVerticalVelocity.Size(), Alpha);
						FVector TargetHorizontal = Player.ActorForwardVector.GetSafeNormal().ConstrainToPlane(MoveComp.WorldUp) * Math::Lerp(RollDashComp.Settings.MinimumSlowdownVelocity, ImpulseHorizontalVelocity.Size(), Alpha);

						Movement.AddHorizontalVelocity(TargetHorizontal);
						Movement.AddVerticalVelocity(TargetVertical);

						if(ActiveDuration - RollDashComp.Settings.RollDashJumpAnticipationDuration >= RollDashComp.Settings.AccelerationDuration && !bDoneAccelerating)
						{
							bDoneAccelerating = true;

							//Handle VFX / FF / Etc
							TriggerLaunchEffects();
						}
					}
					else
					{
						//If we had anticipationDuration set then deccelerate here prior to being launched
						FVector CurrentHorizontalVelocity = MoveComp.GetHorizontalVelocity();
						FVector TargetDirection = InitialDirection;
						FVector TargetHorizontalVelocity = TargetDirection * Math::Lerp(CurrentHorizontalVelocity.Size(), RollDashComp.Settings.MinimumSlowdownVelocity, ActiveDuration / (RollDashComp.Settings.RollDashJumpAnticipationDuration));

						// Movement.AddDelta(TargetHorizontalVelocity * DeltaTime);
						Movement.AddOwnerVerticalVelocity();
						Movement.AddGravityAcceleration();
						Movement.AddHorizontalVelocity(TargetHorizontalVelocity);
					}
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Jump");
		}
	}

	void GetGroundAlignedAdjustedVelocity(FVector& HorizontalVelocity, FVector& VerticalVelocity) const
	{
		if(!MoveComp.IsOnWalkableGround())
			return;

		FVector GroundNormal = MoveComp.GetCurrentGroundNormal();
		float SlopeDot = GroundNormal.DotProduct(Owner.ActorForwardVector);
		float SlopeAngle = Math::RadiansToDegrees(SlopeDot);
		float Alpha = Math::Abs(SlopeAngle) / MoveComp.WalkableSlopeAngle;

		// Downhill
		if (SlopeDot > KINDA_SMALL_NUMBER)
		{
			// align the horizontal velocity with the world up, 
			//making us leave the ground and not follow the slope down
			FVector HorizontalAlignedVelocity = HorizontalVelocity.VectorPlaneProject(MoveComp.WorldUp).GetSafeNormal() * HorizontalVelocity.Size();	
			Alpha = Math::EaseOut(0.0, 1.0, Alpha, 2.0);
			HorizontalVelocity = Math::Lerp(HorizontalVelocity, HorizontalAlignedVelocity, Alpha);
		}
		// Uphill
		else if(SlopeDot < -KINDA_SMALL_NUMBER)
		{
			//Increase our vertical velocity to make sure we get some air time regardless of slope angle
			float Mul = Math::Lerp(1, 1.35, Alpha);
			VerticalVelocity *= Mul;
		}
	}

	void TriggerLaunchEffects()
	{
		//Moving FF trigger to on activated

		// //Force Feedback / Controller effects
		// switch(InputComp.ControllerType)
		// {
		// 	case EHazePlayerControllerType::Xbox:
		// 	if(RollDashComp.RollDashJumpFF != nullptr)
		// 		Player.PlayForceFeedback(RollDashComp.RollDashJumpFF, false, false, this);
		// 	break;
			
		// 	case EHazePlayerControllerType::PS4:
		// 	case EHazePlayerControllerType::PS5:
		// 		Player.PlayForceFeedback(RollDashComp.RollDashJumpFF, false, false, this);
		// 		// Player.ApplyGamepadLightColor(FColor::Purple, this);
		// 	break;

		// 	case EHazePlayerControllerType::Keyboard:
		// 	break;

		// 	default:
		// 	break;
		// }

		if(RollDashComp.RollDashJumpCameraShake != nullptr)
			Player.PlayCameraShake(RollDashComp.RollDashJumpCameraShake, this);
		
		//Unsure about camera impulse

		// FHazeCameraImpulse CamImpulse = FHazeCameraImpulse();
		// CamImpulse.WorldSpaceImpulse = Player.ViewRotation.ForwardVector * 750	;
		// CamImpulse.Dampening = 0.85;
		// CamImpulse.ExpirationForce = 50;
		// Player.ApplyCameraImpulse(CamImpulse, this);

		UPlayerCoreMovementEffectHandler::Trigger_RollDashJumpStarted(Player);
	}
};