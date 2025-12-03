class UAdultDragonAirBreakCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"AdultDragon");
	default CapabilityTags.Add(n"AdultDragonAirBreak");
	default CapabilityTags.Add(n"AdultDragonFlying");

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 88;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = n"AdultDragon";

	UAdultDragonAirBreakSettings BreakSettings;
	UAdultDragonFlightSettings FlightSettings;

	UAdultDragonAirBreakComponent AirBreakComp;
	UPlayerMovementComponent MoveComp;
	UPlayerAdultDragonComponent DragonComp;

	USimpleMovementData Movement;

	float SpeedAtActivation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BreakSettings = UAdultDragonAirBreakSettings::GetSettings(Player);
		FlightSettings = UAdultDragonFlightSettings::GetSettings(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		AirBreakComp = UAdultDragonAirBreakComponent::Get(Player);
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!IsActioning(ActionNames::Cancel) && !IsActioning(ActionNames::SecondaryLevelAbility))
			return false;

		// So you can't spam
		if(DeactiveDuration < 0.5)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!IsActioning(ActionNames::Cancel) && !IsActioning(ActionNames::SecondaryLevelAbility))
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AirBreakComp.bIsBreaking = true;
		SpeedAtActivation = DragonComp.Speed;
		DragonComp.AnimationState.Apply(EAdultDragonAnimationState::Hover, this);
		
		// UCameraSettings CamSettings = UCameraSettings::GetSettings(Player);
		// FHazeCameraSettingsPriority Priority;
		// CamSettings.FOV.Apply(10.0, 1.0, this, Priority);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AirBreakComp.bIsBreaking = false;
		
		DragonComp.Speed += BreakSettings.BreakEndImpulse; 
		DragonComp.ApplyCameraLag(BreakSettings.CameraLagDuration);

		DragonComp.AnimationState.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				if(DragonComp.Speed > 0)
				{
					DragonComp.Speed = Math::Lerp(
						SpeedAtActivation,
						0,
						ActiveDuration / BreakSettings.BreakTime
					);
					DragonComp.Speed = Math::Max(DragonComp.Speed, 0);
				}
				UpdateWantedRotation(DeltaTime);
				RotateTowardsWantedRotation(DeltaTime);

				FVector Velocity = Player.ActorForwardVector * DragonComp.Speed;
				Movement.AddDelta(Velocity * DeltaTime);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			DragonComp.RequestLocomotionDragonAndPlayer(n"AdultDragonFlying");
			MoveComp.ApplyMove(Movement);
		}

	}

	void UpdateWantedRotation(float DeltaTime)
	{
		FVector MovementInput = MoveComp.MovementInput;
		DragonComp.WantedRotation.Yaw += MovementInput.Y * BreakSettings.WantedYawSpeed * DeltaTime;
		DragonComp.WantedRotation.Pitch += MovementInput.X * BreakSettings.WantedPitchSpeed * DeltaTime;
		DragonComp.WantedRotation.Pitch = Math::Clamp(DragonComp.WantedRotation.Pitch, -BreakSettings.PitchMaxAmount, BreakSettings.PitchMaxAmount);
	}

	void RotateTowardsWantedRotation(float DeltaTime)
	{
		DragonComp.AccRotation.AccelerateTo(DragonComp.WantedRotation, BreakSettings.RotationAcceleration, DeltaTime);
		Movement.SetRotation(DragonComp.AccRotation.Value);
	}
};
