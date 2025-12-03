struct FPinballMagnetDashActivateParams
{
	FRotator InitialDirection;
	float EnterSpeed;
	float ExitSpeed;
};

struct FPinballMagnetDashDeactivateParams
{
	bool bNatural = false;
	bool bWasInterrupted = false;
};

class UPinballMagnetDashCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(DroneCommonTags::DroneDashCapability);

	default BlockExclusionTags.Add(MagnetDroneTags::MagnetDroneSurfaceDash);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90;    // Tick before DroneDashCapability

	UMagnetDroneComponent DroneComp;
	UMagnetDroneAttachedComponent AttachedComp;

	UHazeMovementComponent MoveComp;
	UMagnetDroneAttachedMovementData MoveData;

    FHazeAcceleratedRotator AccDir;
	float ExitSpeed;
	float EnterSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DroneComp = UMagnetDroneComponent::Get(Player);
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Player);
		MoveData = MoveComp.SetupMovementData(UMagnetDroneAttachedMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPinballMagnetDashActivateParams& Params) const 
	{
		if(!HasControl())
			return false;

		if(!WasActionStartedDuringTime(ActionNames::MovementDash, AttachedComp.Settings.DashInputBufferWindow))
			return false;

		if(!AttachedComp.IsAttachedToSurface())
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!MoveComp.IsOnWalkableGround())
			return false;

		if(DeactiveDuration < AttachedComp.Settings.DashCooldown)
			return false;

        Params.EnterSpeed = AttachedComp.Settings.DashEnterSpeed * MoveComp.MovementSpeedMultiplier;

		if(MoveComp.MovementInput.IsNearlyZero())
		{
			Params.InitialDirection = FRotator::MakeFromXZ(DroneComp.CalculateDesiredRotation().ForwardVector, MoveComp.WorldUp);
			Params.ExitSpeed = AttachedComp.Settings.DashExitSpeed;
		}
		else
		{
        	Params.InitialDirection = FRotator::MakeFromXZ(AttachedComp.GetMagnetMoveInput(GetAttributeVector2D(AttributeVectorNames::MovementRaw), MoveComp.WorldUp), MoveComp.WorldUp);
			Params.ExitSpeed = AttachedComp.Settings.DashMaximumSpeed + AttachedComp.Settings.DashSprintExitBoost;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPinballMagnetDashDeactivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!AttachedComp.IsAttachedToSurface())
			return true;

		if(ActiveDuration > AttachedComp.Settings.DashDuration)
			return true;

		if(MoveComp.HasWallContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPinballMagnetDashActivateParams Params)
	{
		DroneComp.bIsDashing = true;

		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementDash);

		AccDir.SnapTo(Params.InitialDirection);
		EnterSpeed = Params.EnterSpeed;
		ExitSpeed = Params.ExitSpeed;

		// Set Start Velocity for the move and add MoveSpeedModifier from movecomp incase its been altered
		Player.SetActorHorizontalVelocity(AccDir.Value.ForwardVector * EnterSpeed);

		if(CanApplyCameraSettings())
		{
			//Apply Camera Settings
			//Player.ApplyCameraSettings(DroneComp.DashCameraSetting, 0.5, this, SubPriority = 89);

			//Apply Camera Shakes
			//Player.PlayCameraShake(DroneComp.DashShake, this, 1.25);

			//Apply Camera Impulses
			FHazeCameraImpulse CamImpulse;
			CamImpulse.AngularImpulse = FRotator(0.0, 0.0, 0.0);
			CamImpulse.CameraSpaceImpulse = FVector(0.0,0.0, 150.0);
			CamImpulse.ExpirationForce = 25.0;
			CamImpulse.Dampening = 0.9;
			Player.ApplyCameraImpulse(CamImpulse, this);
		}

		UDroneEventHandler::Trigger_DashStart(Player);
		UMagnetDroneEventHandler::Trigger_MagnetDroneDash(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPinballMagnetDashDeactivateParams Params)
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
		float Alpha = ActiveDuration / AttachedComp.Settings.DashDuration;
		float CurvedAlpha = DroneComp.DashCurve.GetFloatValue(Alpha);

		float Speed = Math::Lerp(ExitSpeed, EnterSpeed, CurvedAlpha);

		FVector HorizontalVelocity;
		const FVector MoveInput = AttachedComp.GetMagnetMoveInput(GetAttributeVector2D(AttributeVectorNames::MovementRaw), MoveComp.WorldUp);

		//Define our direction based on input and allow it to snap within timeframe.
		if (!MoveInput.IsNearlyZero())
			AccDir.AccelerateTo(FRotator::MakeFromX(MoveInput.GetSafeNormal()), AttachedComp.Settings.DashTurnDuration, DeltaTime);

		//Limit turnrate until certain time has passed
		float TurnRateScale = (ActiveDuration - (AttachedComp.Settings.DashDuration * 0.65)) / (AttachedComp.Settings.DashDuration - (AttachedComp.Settings.DashDuration * 0.65));
		TurnRateScale = Math::Max(SMALL_NUMBER, TurnRateScale);

		HorizontalVelocity = AccDir.Value.ForwardVector * Speed;
		HorizontalVelocity = HorizontalVelocity.RotateVectorTowardsAroundAxis(AccDir.Value.ForwardVector, MoveComp.WorldUp, 720.0 * TurnRateScale * MoveInput.Size() * DeltaTime);

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