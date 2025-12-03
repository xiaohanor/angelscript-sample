class UMagnetDroneSurfaceDashCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
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
	bool ShouldActivate() const 
	{
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

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
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
	void OnActivated()
	{
		DroneComp.bIsDashing = true;

		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementDash);

		if(MoveComp.MovementInput.IsNearlyZero())
		{
			AccDir.Value = FRotator::MakeFromXZ(DroneComp.CalculateDesiredRotation().ForwardVector, MoveComp.WorldUp);
			ExitSpeed = AttachedComp.Settings.DashExitSpeed;
		}
		else
		{
        	AccDir.Value = FRotator::MakeFromXZ(AttachedComp.GetMagnetMoveInput(GetAttributeVector2D(AttributeVectorNames::MovementRaw), MoveComp.WorldUp), MoveComp.WorldUp);
			ExitSpeed = AttachedComp.Settings.DashMaximumSpeed + AttachedComp.Settings.DashSprintExitBoost;
		}

		// Set Start Velocity for the move and add MoveSpeedModifier from movecomp incase its been altered
        EnterSpeed = AttachedComp.Settings.DashEnterSpeed * MoveComp.MovementSpeedMultiplier;
		Player.SetActorHorizontalVelocity(AccDir.Value.ForwardVector * EnterSpeed);

        // enable Tyko special movement magic
		// prevent the drone from rolling off the edge (even with super high velocity)
		Player.AddMovementAlignsWithAnyContact( this, bCanFallOfEdges = false);

		UMovementSweepingSettings::SetRemainOnGroundMinTraceDistance(
			Player,
			FMovementSettingsValue::MakePercentage(MagnetDrone::MagnetGroundTraceDistanceCantFallOff),
			this,
			EHazeSettingsPriority::Gameplay
		);

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
	void OnDeactivated()
	{
		DroneComp.bIsDashing = false;

		Player.ClearCameraSettingsByInstigator(this, 1.0);
		
        Player.RemoveMovementAlignsWithAnyContact(this);
		UMovementSweepingSettings::ClearRemainOnGroundMinTraceDistance(Player, this, EHazeSettingsPriority::Gameplay);

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