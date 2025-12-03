
class UTundraPlayerOtterSwimmingDashCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerMovementTags::Swimming);
	default CapabilityTags.Add(PlayerSwimmingTags::SwimmingDash);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 30;
	default TickGroupSubPlacement = 20;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UTundraPlayerOtterSwimmingComponent SwimmingComp;
	UTundraPlayerOtterComponent OtterComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	bool bCameraSettingsActive = false;
	FDashMovementCalculator DashMovementCalc;

	FVector Direction;
	bool bIsOnSurface = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		SwimmingComp = UTundraPlayerOtterSwimmingComponent::GetOrCreate(Player);
		OtterComp = UTundraPlayerOtterComponent::Get(Player);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!SwimmingComp.IsSwimming())
			return false;

		if (!WasActionStarted(ActionNames::MovementDash))
			return false;
		
		if (DeactiveDuration < SwimmingComp.Settings.DashCooldown)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!SwimmingComp.IsSwimming())
			return true;

		if (DashMovementCalc.IsFinishedAtTime(ActiveDuration))
			return true;

		if (MoveComp.HasImpulse())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		//Check camera setting status
		if (bCameraSettingsActive)
		{
			if (IsBlocked() || (!IsActive() && DeactiveDuration > SwimmingComp.Settings.DashCameraSettingsLingerTime))
			{
				Player.ClearCameraSettingsByInstigator(this, 2.5);
				bCameraSettingsActive = false;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementDash);
		Player.PlayForceFeedback(OtterComp.SwimmingDashForceFeedback, false, false, this);

		SwimmingComp.AnimData.bDashingThisFrame = true;

		if (PerspectiveModeComp.IsCameraBehaviorEnabled())
		{
			Player.PlayCameraShake(OtterComp.SwimmingDashCameraShake, this);
			
			//Apply Camera Settings
			Player.ApplyCameraSettings(SwimmingComp.DashCameraSetting, .5, this, SubPriority = 36);
			bCameraSettingsActive = true;

			//Clamp FoV based on current state and make sure it cant constantly get higher with consecutive dashes.
			float TargetFOV = Math::Min(Player.ViewFOV + 5.0, 75.0);

			// Apply the FOV relative to current FOV so it's not so extreme when sprinting
			UCameraSettings::GetSettings(Player).FOV.Apply(TargetFOV, this, 0.5, SubPriority = 36);

			//Apply Camera Impulses
			FHazeCameraImpulse CamImpulse;
			CamImpulse.AngularImpulse = FRotator(0.0, 0.0, 0.0);
			CamImpulse.CameraSpaceImpulse = FVector(150.0,0.0,0.0);
			CamImpulse.ExpirationForce = 25.0;
			CamImpulse.Dampening = 0.9;
			Player.ApplyCameraImpulse(CamImpulse, this);
		}


		bIsOnSurface = SwimmingComp.CurrentState == ETundraPlayerOtterSwimmingState::Surface;
		float ExitSpeed = bIsOnSurface ? SwimmingComp.Settings.DashExitSpeed : SwimmingComp.Settings.Underwater_DashExitSpeed;

		if(SwimmingComp.Settings.bSwimDashFollowMovementInput)
		{
			FVector MoveDirection;
			FVector2D RawMoveInput2D = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			FVector RawMoveInput = FVector(RawMoveInput2D.X, RawMoveInput2D.Y, 0.0);

			if (PerspectiveModeComp.GetPerspectiveMode() == EPlayerMovementPerspectiveMode::SideScroller)
			{
				// When in sidescroller movement, we want to swim up or down with the stick
				MoveDirection = Player.ViewRotation.RotateVector(FVector(
					0.0, RawMoveInput2D.Y, RawMoveInput2D.X,
				));

				float VerticalScale = 0.0;
				if (IsActioning(ActionNames::MovementVerticalUp))
					VerticalScale += 1.5;
				if (IsActioning(ActionNames::MovementVerticalDown))
					VerticalScale -= 1.5;

				MoveDirection.Z += VerticalScale;
			}
			else
			{
				// In 3D or topdown movement, use separate input for up and down
				float VerticalScale = 0.0;
				if (IsActioning(ActionNames::MovementVerticalUp))
					VerticalScale += 1.5;
				if (IsActioning(ActionNames::MovementVerticalDown))
					VerticalScale -= 1.5;

				MoveDirection = Player.ViewRotation.RotateVector(RawMoveInput) + (MoveComp.WorldUp * VerticalScale);
			}

			Direction = MoveDirection.GetSafeNormal();
		}
		else
		{
			Direction = MoveComp.Velocity.GetSafeNormal();
		}

		if (Direction.IsNearlyZero())
			Direction = Player.ActorForwardVector;

		if (bIsOnSurface)
			Direction = Direction.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		

		DashMovementCalc = FDashMovementCalculator(
			GetCapabilityDeltaTime(),
			DashDistance = bIsOnSurface ? SwimmingComp.Settings.DashDistance : SwimmingComp.Settings.Underwater_DashDistance,
			DashDuration = bIsOnSurface ? SwimmingComp.Settings.DashDuration : SwimmingComp.Settings.Underwater_DashDuration,
			DashAccelerationDuration = bIsOnSurface ? SwimmingComp.Settings.DashAccelerationDuration : SwimmingComp.Settings.Underwater_DashAccelerationDuration,
			DashDecelerationDuration = bIsOnSurface ? SwimmingComp.Settings.DashDecelerationDuration : SwimmingComp.Settings.Underwater_DashDecelerationDuration,
			InitialSpeed = Player.GetActorHorizontalVelocity().Size(),
			WantedExitSpeed = ExitSpeed,
		);

		FSwimmingEffectEventData Data;
		Data.SurfaceLocation = SwimmingComp.SurfaceData.SurfaceLocation;

		if(SwimmingComp.CurrentState == ETundraPlayerOtterSwimmingState::Surface)
		{
			SwimmingComp.SetCurrentState(ETundraPlayerOtterSwimmingState::SurfaceDash);
			UPlayerSwimmingEffectHandler::Trigger_Surface_DashStarted(Player, Data);
		}
		else if(SwimmingComp.CurrentState == ETundraPlayerOtterSwimmingState::Underwater)
		{
			SwimmingComp.SetCurrentState(ETundraPlayerOtterSwimmingState::UnderwaterDash);
			UPlayerSwimmingEffectHandler::Trigger_Underwater_DashStarted(Player, Data);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SwimmingComp.AnimData.bDashingThisFrame = false;

		// If we dashed out of the water, clamp velocity so vertical speed is not higher than jump out of strength. But we want to preserve the direction so we can't just clamp the vertical velocity and keep the horizontal speed because then the direction would change.
		//	   /
		// ___X________ (Plane)
		//   /
		//  /
		// /
		if(!SwimmingComp.IsSwimming())
		{
			FPlane Plane = FPlane(Player.MovementWorldUp * SwimmingComp.Settings.MaxDashOutOfSurfaceSpeed, Player.MovementWorldUp);
			FVector Result = Plane.RayPlaneIntersection(FVector::ZeroVector, Player.ActorVelocity);

			if(!Result.ContainsNaN())
				Player.ActorVelocity = Result;
		}

		// Don't allow inheriting the horizontal speed from a dash when we cancel it
		Player.SetActorHorizontalVelocity(
			Player.ActorHorizontalVelocity.GetClampedToMaxSize(DashMovementCalc.GetExitSpeed())
		);

		FSwimmingEffectEventData Data;
		Data.SurfaceLocation = SwimmingComp.SurfaceData.SurfaceLocation;

		if(SwimmingComp.GetCurrentState()== ETundraPlayerOtterSwimmingState::SurfaceDash)
			UPlayerSwimmingEffectHandler::Trigger_Surface_DashStopped(Player, Data);
		else if(SwimmingComp.GetCurrentState() == ETundraPlayerOtterSwimmingState::UnderwaterDash)
		{
			FTundraPlayerOtterSwimmingSurfaceData SurfaceData;
			if(SwimmingComp.CheckForSurface(Player, SurfaceData) && SurfaceData.DistanceToSurface < SwimmingComp.Settings.SurfaceRangeFromUnderwater)
				UPlayerSwimmingEffectHandler::Trigger_Surface_DashBreach(Player, Data);

			UPlayerSwimmingEffectHandler::Trigger_Underwater_DashStopped(Player, Data);
		}
		else
		{
			//Incase something swapped the state or we somehow exited swimming and state turned inactive
			if(bIsOnSurface)
				UPlayerSwimmingEffectHandler::Trigger_Surface_DashStopped(Player, Data);
			else
				UPlayerSwimmingEffectHandler::Trigger_Underwater_DashStopped(Player, Data);

			FTundraPlayerOtterSwimmingSurfaceData SurfaceData;
			bool bFoundSurface = SwimmingComp.CheckForSurface(Player,SurfaceData);
			if((bFoundSurface && SurfaceData.DistanceToSurface < SwimmingComp.Settings.SurfaceRangeFromUnderwater) || !bFoundSurface)
				UPlayerSwimmingEffectHandler::Trigger_Surface_DashBreach(Player, Data);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				float FrameMovement;
				float FrameSpeed;

				DashMovementCalc.CalculateMovement(
					ActiveDuration, DeltaTime,
					FrameMovement, FrameSpeed
				);

				Movement.AddDeltaWithCustomVelocity(
					Direction * FrameMovement,
					Direction * FrameSpeed,
					EMovementDeltaType::Native
				);

				FRotator TargetRotation = Owner.ActorRotation;
				FVector HorizontalMoveDirection = Direction.ConstrainToPlane(MoveComp.WorldUp);
				if (!HorizontalMoveDirection.IsNearlyZero())
				{
					TargetRotation = FRotator::MakeFromXZ(HorizontalMoveDirection, MoveComp.WorldUp);
					TargetRotation.Pitch = 0.0;
				}

				Movement.InterpRotationTo(TargetRotation.Quaternion(), bIsOnSurface ? SwimmingComp.Settings.SwimDashRotationInterpSpeed : SwimmingComp.Settings.Underwater_SwimDashRotationInterpSpeed);
			}
			else
			{
				FVector MoveDirection = MoveComp.SyncedMovementInputForAnimationOnly;
				SwimmingComp.AnimData.MovementScale = MoveDirection.Size();
				SwimmingComp.AnimData.WantedDirection = MoveDirection.GetSafeNormal();
				SwimmingComp.AnimData.CurrentDirection = MoveComp.Velocity.GetSafeNormal();

				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);

			if (bIsOnSurface)
				Player.Mesh.RequestLocomotion(n"SurfaceSwimming", this);
			else
				Player.Mesh.RequestLocomotion(n"UnderwaterSwimming", this);
		}
	}
}