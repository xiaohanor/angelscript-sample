class UControlledBabyDragonDashCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);

	//Define new tag for Dodge?
	default CapabilityTags.Add(PlayerMovementTags::Dash);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 39;
	default TickGroupSubPlacement = 1;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerStepDashComponent DashComp;

	FVector Dir;
	float ExitSpeed;
	float EnterSpeed;
	float CurrDashCooldown;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		DashComp = UPlayerStepDashComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		//tick cooldown
		if(CurrDashCooldown > 0.0)
			CurrDashCooldown -= DeltaTime;
		else
			CurrDashCooldown = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!MoveComp.IsOnWalkableGround())
			return false;

		//Input Buffer Window
		if(!WasActionStartedDuringTime(ActionNames::MovementDash, DashComp.Settings.InputBufferWindow))
			return false;
		
		if(CurrDashCooldown > 0.0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(ActiveDuration >= ControlledBabyDragon::DashDuration)
			return true;

		if(MoveComp.HasUpwardsImpulse())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::Dash, this);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementDash);

		ExitSpeed = ControlledBabyDragon::MaxMoveSpeed;

		Dir = MoveComp.MovementInput.GetSafeNormal();
		if (MoveComp.MovementInput.IsNearlyZero())
			Dir = Player.ActorForwardVector;

		// Set Start Velocity for the move and add MoveSpeedModifier from movecomp incase its been altered
		EnterSpeed = ControlledBabyDragon::DashSpeed * MoveComp.MovementSpeedMultiplier;
		Player.SetActorHorizontalVelocity(Dir * EnterSpeed);

		// Apply Camera Impulses
		FHazeCameraImpulse CamImpulse;
		CamImpulse.AngularImpulse = FRotator(0.0, 0.0, 0.0);
		CamImpulse.CameraSpaceImpulse = FVector(0.0,0.0, 150.0);
		CamImpulse.ExpirationForce = 25.0;
		CamImpulse.Dampening = 0.9;
		Player.ApplyCameraImpulse(CamImpulse, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::Dash, this);
		CurrDashCooldown = ControlledBabyDragon::DashCooldown;

		Player.ClearCameraSettingsByInstigator(this, 2.5);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				//Calculate Speed Based on Current Duration
				float DashDuration = ControlledBabyDragon::DashDuration;
				float Alpha = ActiveDuration / DashDuration;
				float Speed = Math::Lerp(ExitSpeed, EnterSpeed, Alpha);

				FVector HorizontalVelocity;
				if (ActiveDuration < DashComp.Settings.RedirectionWindow)
				{
					//Snap the velocity to input direction within the window
					if (!MoveComp.MovementInput.IsNearlyZero())
						HorizontalVelocity =  MoveComp.MovementInput.GetSafeNormal() * Speed;
					else
						HorizontalVelocity = Player.ActorForwardVector * Speed;
				}
				else
				{
					//Limit turnrate until certain time has passed
					float TurnRateScale = (ActiveDuration - (DashDuration * 0.65)) / (DashDuration - (DashDuration * 0.65));
					TurnRateScale = Math::Max(SMALL_NUMBER, TurnRateScale);

					HorizontalVelocity = MoveComp.HorizontalVelocity.GetSafeNormal() * Speed;
					HorizontalVelocity =  HorizontalVelocity.RotateVectorTowardsAroundAxis(MoveComp.MovementInput.GetSafeNormal(), MoveComp.WorldUp, 720.0 * TurnRateScale * MoveComp.MovementInput.Size() * DeltaTime);
				}

				Movement.SetRotation(HorizontalVelocity.ToOrientationQuat());
				Movement.AddHorizontalVelocity(HorizontalVelocity);
				
				Movement.AddGravityAcceleration();
				Movement.AddOwnerVerticalVelocity();
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"Dash");
		}
	}
};