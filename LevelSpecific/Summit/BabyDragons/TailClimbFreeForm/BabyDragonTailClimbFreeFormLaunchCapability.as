
class UBabyDragonTailClimbFreeFormLaunchCapability: UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(BabyDragon::BabyDragon);
	default CapabilityTags.Add(n"TailClimb");

	default BlockExclusionTags.Add(n"TailClimb");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 7;
	default TickGroupSubPlacement = 3;

	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 7, 1);

	/** SETTINGS */
	bool bInheritPlatformMovement = true;
	/** ***** */

	UPlayerTailBabyDragonComponent DragonComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerAirMotionComponent AirMotionComp;
	UPlayerLedgeGrabComponent LedgeGrabComp;

	bool bUseGroundedTraceDistance = false;
	bool bHasLockedInput = false;
	float LastTimeLockedInput;
	FVector PlayerActivationForward;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailBabyDragonComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		AirMotionComp = UPlayerAirMotionComponent::GetOrCreate(Player);
		LedgeGrabComp = UPlayerLedgeGrabComponent::GetOrCreate(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FBabyDragonTailClimbFreeFormCapabilityActivation& ActivationParams) const
	{
		if(MoveComp.IsOnAnyGround())
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!DragonComp.bTriggerLaunchForce)
			return false;

		if(DragonComp.ClimbLaunchForce.IsNearlyZero())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.IsOnAnyGround())
			return true;

		if(MoveComp.HasMovedThisFrame())
			return true;
		
		if(!DragonComp.bInvertTailClimbLaunchForce)
		{
			if(ActiveDuration >= BabyDragonTailClimbSettings::ReTriggerDelay 
				&& !WasActionStarted(ActionNames::PrimaryLevelAbility))
				return true;
		}
		else 
		{
			if(Time::GameTimeSeconds > DragonComp.NextAutomaticReTriggerTime)
				return true;

			if(WasActionStarted(ActionNames::PrimaryLevelAbility))
				return true;
		}
	
		// Deactivate when we are falling fast
		if(MoveComp.Velocity.DotProduct(-Player.GetMovementWorldUp()) > 500)
			return true;

		FPlayerLedgeGrabData LedgeGrabData;
		if (LedgeGrabComp.TraceForLedgeGrab(Player, Player.ActorForwardVector, LedgeGrabData, this, IsDebugActive()))
		{
			if(!LedgeGrabData.TopHitComponent.HasTag(n"LedgeGrabbable"))
				return false;

			LedgeGrabComp.Data = LedgeGrabData;
			return true;
		}
			
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FBabyDragonTailClimbFreeFormCapabilityActivation ActivationParams)
	{	
		// Removed blocking of capabilities / Pussel
		// Player.BlockCapabilities(PlayerMovementTags::CoreMovement, this);
		// Player.BlockCapabilitiesExcluding(CapabilityTags::GameplayAction, n"TailClimb", this);
		// Player.BlockCapabilities(n"ContextualMoves", this);
		// Player.BlockCapabilities(BlockedWhileIn::AirMotion, this);
		// Add the jump impulse
		
		FVector Impulse = DragonComp.ClimbLaunchForce;
		if(bInheritPlatformMovement)
			Impulse += MoveComp.GetFollowVelocity().VectorPlaneProject(Player.ActorForwardVector);
		Player.AddMovementImpulse(Impulse, n"DragonTailJump");
		const float ImpulseAlpha = Math::Min(Impulse.Size() / BabyDragonTailClimbSettings::LaunchForce.Max, 1);
		
		Player.ApplyCameraSettings(DragonComp.ClimbCameraSettings, 3, this, SubPriority = 100);
		Player.PlayForceFeedback(DragonComp.ClimbLaunchRumble, false, true, this, ImpulseAlpha);

		DragonComp.NextAutomaticReTriggerTime = 0;
		if(DragonComp.bInvertTailClimbLaunchForce)
		{
			DragonComp.NextAutomaticReTriggerTime = BabyDragonTailClimbSettings::LaunchForceAutomaticReTriggerTime.Lerp(ImpulseAlpha);
			DragonComp.NextAutomaticReTriggerTime += Time::GameTimeSeconds;
		}

		auto ResponseComp = UBabyDragonTailClimbFreeFormResponseComponent::Get(DragonComp.AttachmentComponent.Owner);
		if(ResponseComp != nullptr)
		{
			if(!ResponseComp.bIsPrimitiveParentExclusive
			|| ResponseComp.AttachmentWasOnParent(DragonComp.AttachmentComponent))
			{
				FBabyDragonTailClimbFreeFormJumpedFromParams Params;
				Params.AttachComponent = DragonComp.AttachmentComponent;
				Params.WorldAttachLocation = DragonComp.AttachmentComponent.WorldTransform.TransformPosition(ActivationParams.RelativeAttachPoint);
				Params.AttachNormal = DragonComp.AttachmentComponent.WorldTransform.TransformVectorNoScale(ActivationParams.RelativeImpactNormal);
				Params.JumpVelocity = DragonComp.ClimbLaunchForce;
				ResponseComp.OnTailJumpedFrom.Broadcast(Params);
			}
		}


		DragonComp.bTriggerLaunchForce = false;
		DragonComp.PreviousClimbLaunchForce = DragonComp.ClimbLaunchForce;
		DragonComp.ClimbLaunchForce = FVector::ZeroVector;
		DragonComp.bClimbReachedPoint = false;
		DragonComp.ClimbBonusTrace = 200; // Make it easier to grab the wall (previous value: 200)
		PlayerActivationForward = Player.ActorForwardVector;	


		if(DragonComp.HorizontalLockVolume.IsSet())
		{
			LastTimeLockedInput = Time::GameTimeSeconds;
			Player.LockInputToPlane(this, -DragonComp.HorizontalLockVolume.Value.ActorRightVector, FVector::ZeroVector, EInstigatePriority::High);
			bHasLockedInput = true;
		}

		DragonComp.ApplyClimbState(ETailBabyDragonClimbState::Transfer, this, EInstigatePriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.ClearClimbStateInstigator(this);

		// Player.UnblockCapabilities(PlayerMovementTags::CoreMovement, this);
		// Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		// Player.UnblockCapabilities(n"ContextualMoves", this);
		// Player.UnblockCapabilities(BlockedWhileIn::AirMotion, this);

		bUseGroundedTraceDistance = false;
		DragonComp.ClimbBonusTrace = 0;
		DragonComp.bTriggerLaunchForce = false;
		DragonComp.ClimbLaunchForce = FVector::ZeroVector;
		DragonComp.bDisableWallStickInitially = false;

		MoveComp.UnFollowComponentMovement(this);
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(bHasLockedInput)
		{
			FVector2D MoveRaw = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

			if(MoveComp.IsOnAnyGround()
			|| Time::GetGameTimeSince(LastTimeLockedInput) > 5.0
			|| !DragonComp.HorizontalLockVolume.IsSet()
			|| MoveRaw.X < -0.2)
			{
				Player.ClearLockInputToPlane(this);
				bHasLockedInput = false;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector AirControlVelocity = AirMotionComp.CalculateStandardAirControlVelocity(
					MoveComp.MovementInput,
					MoveComp.HorizontalVelocity,
					DeltaTime,
				);

				// Make sure we don't move away from the wall
				if(ActiveDuration < 0.5
				&& !DragonComp.bDisableWallStickInitially)
					AirControlVelocity = AirControlVelocity.ConstrainToPlane(PlayerActivationForward);
				
				Movement.AddHorizontalVelocity(AirControlVelocity);

				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.AddPendingImpulses();

				TEMPORAL_LOG(Player, "Baby Dragon Climb")
					.DirectionalArrow("Player Activation Forward", Player.ActorLocation, PlayerActivationForward * 500, 20, 40, FLinearColor::Red)
					.DirectionalArrow("AirControlVelocity", Player.ActorLocation, AirControlVelocity, 20, 40, FLinearColor::LucBlue)
				;
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			if(!MoveComp.bHasPerformedAnyMovementSinceReset || bUseGroundedTraceDistance)
			{
				Movement.ForceGroundedStepDownSize();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AirMovement");
		}
	
	}
};