

class UGoatBlinkCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	UHazeMovementComponent MoveComp;
	USweepingMovementData MoveData;
	UGenericGoatPlayerComponent GoatComp;
	UGoatBlinkPlayerComponent BlinkComp;

    FHazeAcceleratedRotator AccDir;
	float ExitSpeed;
	float EnterSpeed;

	float BlinkDuration = 0.15;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		MoveData = MoveComp.SetupSweepingMovementData();
		GoatComp = UGenericGoatPlayerComponent::Get(Player);
		BlinkComp = UGoatBlinkPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const 
	{
		if(!WasActionStartedDuringTime(ActionNames::MovementDash, 0.08))
			return false;

        if(MoveComp.HasMovedThisFrame())
            return false;

        if(!MoveComp.IsOnWalkableGround())
			return false;

        if(DeactiveDuration < 0.2)
            return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
        if(MoveComp.HasMovedThisFrame())
            return true;

        if(ActiveDuration > BlinkDuration)
            return true;

		if(!MoveComp.IsOnWalkableGround())
			return true;

		if(MoveComp.HasWallContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementDash);

		if(MoveComp.MovementInput.IsNearlyZero())
		{
			AccDir.Value = FRotator::MakeFromX(Player.ActorForwardVector);
			ExitSpeed = 1000;
		}
		else
		{
        	AccDir.Value = FRotator::MakeFromX(MoveComp.MovementInput);
			ExitSpeed = 1000.0 + 50.0;
		}

		// Set Start Velocity for the move and add MoveSpeedModifier from movecomp incase its been altered
        EnterSpeed = 8000.0 * MoveComp.MovementSpeedMultiplier;
		Player.SetActorHorizontalVelocity(AccDir.Value.ForwardVector * EnterSpeed);

		if (!SceneView::IsFullScreen())
		{
			//Apply Camera Settings
			/*Player.ApplyCameraSettings(DroneComp.DashCameraSetting, 0.5, this, FHazeCameraSettingsPriority(this));

			//Apply Camera Shakes
			Player.PlayCameraShake(DroneComp.DashShake, this, .5);

			//Apply Camera Impulses
			FHazeCameraImpulse CamImpulse;
			CamImpulse.AngularImpulse = FRotator(0.0, 0.0, 0.0);
			CamImpulse.CameraSpaceImpulse = FVector(-200.0, 0.0, 0.0);
			CamImpulse.ExpirationForce = 25.0;
			CamImpulse.Dampening = 0.9;
			Player.ApplyCameraImpulse(CamImpulse, this);*/
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// DroneComp.DashFrame = Time::FrameNumber;

        if(!MoveComp.PrepareMove(MoveData))
            return;

        if(HasControl())
        {
            //Calculate Speed Based on Current Duration
            float Alpha = ActiveDuration / BlinkDuration;
            float CurvedAlpha = BlinkComp.BlinkCurve.GetFloatValue(Alpha);

			if (!SceneView::IsFullScreen())
				SpeedEffect::RequestSpeedEffect(Player, CurvedAlpha, this, EInstigatePriority::Normal);

            float Speed = Math::Lerp(ExitSpeed, EnterSpeed, CurvedAlpha);

            FVector HorizontalVelocity;

            //Define our direction based on input and allow it to snap within timeframe.
			FVector InputWorldUp = MoveComp.WorldUp;
			if(MoveComp.IsOnWalkableGround())
				InputWorldUp = MoveComp.GroundContact.ImpactNormal;

			const FVector MoveInput = MoveComp.MovementInput;
			
            //Define our direction based on input and allow it to snap within timeframe.
			if (!MoveInput.IsNearlyZero())
				AccDir.AccelerateTo(FRotator::MakeFromX(MoveInput.GetSafeNormal()), 0.05, DeltaTime);

            //Limit turnrate until certain time has passed
            float TurnRateScale = (ActiveDuration - (BlinkDuration * 0.65)) / (BlinkDuration - (BlinkDuration * 0.65));
            TurnRateScale = Math::Max(SMALL_NUMBER, TurnRateScale);

            HorizontalVelocity = AccDir.Value.ForwardVector * Speed;
            HorizontalVelocity = HorizontalVelocity.RotateVectorTowardsAroundAxis(MoveComp.MovementInput.GetSafeNormal(), MoveComp.WorldUp, 720.0 * TurnRateScale * MoveComp.MovementInput.Size() * DeltaTime);

            MoveData.SetRotation(HorizontalVelocity.ToOrientationQuat());
            MoveData.AddVelocity(HorizontalVelocity);

            MoveData.AddGravityAcceleration();
            MoveData.AddOwnerVerticalVelocity();
        }
        else
        {
            MoveData.ApplyCrumbSyncedGroundMovement();
        }

		// if(DroneComp.MovementSettings.bUseGroundStickynessWhileDashing)
			// MoveData.UseGroundStickynessThisFrame();

		MoveData.AddPendingImpulses();

        MoveComp.ApplyMove(MoveData);

        if(IsDebugActive())
        {
            PrintToScreenScaled("DashVel: " + MoveComp.HorizontalVelocity.Size(), Color = FLinearColor::Yellow);
        }
	}
}