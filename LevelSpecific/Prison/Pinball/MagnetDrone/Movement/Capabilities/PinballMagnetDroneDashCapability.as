struct FPinballMagnetDroneDashDeactivateParams
{
	bool bNatural = false;
	bool bWasInterrupted = false;
};

class UPinballMagnetDroneDashCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default DebugCategory = Drone::DebugCategory;
	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(DroneCommonTags::DroneDashCapability);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 100;

	UMagnetDroneComponent DroneComp;
	UHazeMovementComponent MoveComp;
	UPinballMagnetDroneMovementData MoveData;

	FVector DashDirection;
	float ExitSpeed;
	float EnterSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DroneComp = UMagnetDroneComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		MoveData = MoveComp.SetupMovementData(UPinballMagnetDroneMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const 
	{
		if(!HasControl())
			return false;
		
		if(!WasActionStartedDuringTime(ActionNames::MovementDash, DroneComp.MovementSettings.DashInputBufferWindow))
			return false;

        if(MoveComp.HasMovedThisFrame())
            return false;

        if(!MoveComp.IsOnWalkableGround())
			return false;

        if(DeactiveDuration < DroneComp.MovementSettings.DashCooldown)
            return false;

		if(MoveComp.MovementInput.IsNearlyZero())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPinballMagnetDroneDashDeactivateParams& Params) const
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

		if(MoveComp.HasWallContact())
		{
			Params.bNatural = true;
			Params.bWasInterrupted = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DroneComp.bIsDashing = true;

		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementDash);

		DashDirection = MoveComp.MovementInput.Y < 0 ? FVector::LeftVector : FVector::RightVector;
		ExitSpeed = DroneComp.MovementSettings.DashMaximumSpeed + DroneComp.MovementSettings.DashSprintExitBoost;

		// Set Start Velocity for the move and add MoveSpeedModifier from movecomp incase its been altered
        EnterSpeed = DroneComp.MovementSettings.DashEnterSpeed * MoveComp.MovementSpeedMultiplier;
		Player.SetActorHorizontalVelocity(DashDirection * EnterSpeed);

		UDroneEventHandler::Trigger_DashStart(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPinballMagnetDroneDashDeactivateParams Params)
	{
		DroneComp.bIsDashing = false;

		if(Params.bNatural)
		{
			// If we are moving upwards
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
		if(!HasControl())
			return;

		DroneComp.DashFrame = Time::FrameNumber;

        if(!MoveComp.PrepareMove(MoveData))
            return;

        if(HasControl())
        {
            float Alpha = ActiveDuration / DroneComp.MovementSettings.DashDuration;
            float CurvedAlpha = DroneComp.DashCurve.GetFloatValue(Alpha);

            float Speed = Math::Lerp(ExitSpeed, EnterSpeed, CurvedAlpha);

            FVector HorizontalVelocity = DashDirection * Speed;

            MoveData.AddVelocity(HorizontalVelocity);

            MoveData.AddGravityAcceleration();
            MoveData.AddOwnerVerticalVelocity();
        }
        else
        {
            MoveData.ApplyCrumbSyncedGroundMovement();
        }

		if(DroneComp.MovementSettings.bUseGroundStickynessWhileDashing)
			MoveData.UseGroundStickynessThisFrame();

		MoveData.AddPendingImpulses();

        MoveComp.ApplyMove(MoveData);
	}
}