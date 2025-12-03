struct FDroneDashActivateParams
{
	FRotator InitialDirection;
	float EnterSpeed;
	float ExitSpeed;
;}

struct FDroneDashDeactivateParams
{
	bool bNatural = false;
	bool bWasInterrupted = false;
};

class UDroneDashCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = Drone::DebugCategory;
	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(DroneCommonTags::DroneDashCapability);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	UHazeMovementComponent MoveComp;
	USweepingMovementData MoveData;
	UDroneComponent DroneComp;

    FHazeAcceleratedRotator AccDir;
	float ExitSpeed;
	float EnterSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		MoveData = MoveComp.SetupSweepingMovementData();
		DroneComp = UDroneComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDroneDashActivateParams& Params) const 
	{
		if(!WasActionStartedDuringTime(ActionNames::MovementDash, DroneComp.MovementSettings.DashInputBufferWindow))
			return false;

        if(MoveComp.HasMovedThisFrame())
            return false;

        if(!MoveComp.IsOnWalkableGround())
			return false;

        if(DeactiveDuration < DroneComp.MovementSettings.DashCooldown)
            return false;

		Params.EnterSpeed = DroneComp.MovementSettings.DashEnterSpeed * MoveComp.MovementSpeedMultiplier;

		if(MoveComp.MovementInput.IsNearlyZero())
		{
			Params.InitialDirection = FRotator::MakeFromX(Player.ActorForwardVector);
			Params.ExitSpeed = DroneComp.MovementSettings.DashExitSpeed;
		}
		else
		{
			Params.InitialDirection = FRotator::MakeFromX(DroneComp.GetMoveInput(MoveComp.MovementInput, MoveComp.WorldUp));
			Params.ExitSpeed = DroneComp.MovementSettings.DashMaximumSpeed + DroneComp.MovementSettings.DashSprintExitBoost;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FDroneDashDeactivateParams& Params) const
	{
        if(MoveComp.HasMovedThisFrame())
		{
			Params.bNatural = true;
			Params.bWasInterrupted = true;
            return true;
		}

        if(ActiveDuration > DroneComp.MovementSettings.DashDuration)
		{
			Params.bNatural = true;
            return true;
		}

		if(!MoveComp.IsOnWalkableGround())
		{
			Params.bNatural = true;
			Params.bWasInterrupted = true;
			return true;
		}

		if(MoveComp.HasWallContact())
		{
			Params.bNatural = true;
			Params.bWasInterrupted = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDroneDashActivateParams Params)
	{
		DroneComp.bIsDashing = true;

		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementDash);

		AccDir.SnapTo(Params.InitialDirection);
		EnterSpeed = Params.EnterSpeed;
		ExitSpeed = Params.ExitSpeed;

		Player.SetActorHorizontalVelocity(AccDir.Value.ForwardVector * EnterSpeed);

		if (CanApplyCameraSettings())
		{
			//Apply Camera Settings
			//Player.ApplyCameraSettings(DroneComp.DashCameraSetting, 0.5, this, SubPriority = 100);

			//Apply Camera Shakes
			//Player.PlayCameraShake(DroneComp.DashShake, this, .5);

			//Apply Camera Impulses
			FHazeCameraImpulse CamImpulse;
			CamImpulse.AngularImpulse = FRotator(0.0, 0.0, 0.0);
			CamImpulse.CameraSpaceImpulse = FVector(-200.0, 0.0, 0.0);
			CamImpulse.ExpirationForce = 25.0;
			CamImpulse.Dampening = 0.9;
			Player.ApplyCameraImpulse(CamImpulse, this);
		}

		UDroneEventHandler::Trigger_DashStart(Player);
		
		if(Player.IsZoe())
			UMagnetDroneEventHandler::Trigger_MagnetDroneDash(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FDroneDashDeactivateParams Params)
	{
		DroneComp.bIsDashing = false;

		if(Params.bNatural && Params.bWasInterrupted)
		{
			// If we are moving upwards, and we were interrupted
			if(MoveComp.Velocity.Z > 0 && MoveComp.Velocity.Size() > ExitSpeed)
			{
				// Clamp our speed just to make sure we don't ping off
				Player.SetActorVelocity(MoveComp.Velocity.GetClampedToMaxSize(ExitSpeed));
			}
		}

		Player.ClearCameraSettingsByInstigator(this, 1.0);

		UDroneEventHandler::Trigger_DashStop(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DroneComp.DashFrame = Time::FrameNumber;

        if(!MoveComp.PrepareMove(MoveData))
            return;

        if(HasControl())
        {
			if(DroneComp.MovementSettings.bUseGroundStickynessWhileDashing)
				MoveData.UseGroundStickynessThisFrame();

			CalculateDeltaMove(DeltaTime);

			MoveData.AddPendingImpulses();
        }
        else
        {
            MoveData.ApplyCrumbSyncedGroundMovement();
        }

        MoveComp.ApplyMove(MoveData);
	}

	void CalculateDeltaMove(float DeltaTime)
	{
		//Calculate Speed Based on Current Duration
		float Alpha = ActiveDuration / DroneComp.MovementSettings.DashDuration;
		float CurvedAlpha = DroneComp.DashCurve.GetFloatValue(Alpha);

		float Speed = Math::Lerp(ExitSpeed, EnterSpeed, CurvedAlpha);

		FVector HorizontalVelocity;

		//Define our direction based on input and allow it to snap within timeframe.
		FVector InputWorldUp = MoveComp.WorldUp;
		if(MoveComp.IsOnWalkableGround())
			InputWorldUp = MoveComp.GroundContact.ImpactNormal;

		const FVector MoveInput = DroneComp.GetMoveInput(MoveComp.MovementInput, InputWorldUp);
		
		//Define our direction based on input and allow it to snap within timeframe.
		if (!MoveInput.IsNearlyZero())
			AccDir.AccelerateTo(FRotator::MakeFromX(MoveInput.GetSafeNormal()), DroneComp.MovementSettings.DashTurnDuration, DeltaTime);

		//Limit turnrate until certain time has passed
		float TurnRateScale = (ActiveDuration - (DroneComp.MovementSettings.DashDuration * 0.65)) / (DroneComp.MovementSettings.DashDuration - (DroneComp.MovementSettings.DashDuration * 0.65));
		TurnRateScale = Math::Max(SMALL_NUMBER, TurnRateScale);

		HorizontalVelocity = AccDir.Value.ForwardVector * Speed;
		HorizontalVelocity = HorizontalVelocity.RotateVectorTowardsAroundAxis(MoveComp.MovementInput.GetSafeNormal(), MoveComp.WorldUp, 720.0 * TurnRateScale * MoveComp.MovementInput.Size() * DeltaTime);

		MoveData.SetRotation(HorizontalVelocity.ToOrientationQuat());
		MoveData.AddVelocity(HorizontalVelocity);

		MoveData.AddGravityAcceleration();
		MoveData.AddOwnerVerticalVelocity();
	}

	bool CanApplyCameraSettings() const
	{
		if(SceneView::IsFullScreen())
			return false;

		if(SceneView::IsPendingFullscreen())
			return false;

		return true;
	}
}