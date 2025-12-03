class UTeenDragonAirGlideInitialBoostCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonAirGlide);

	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 30;

	UPlayerMovementComponent MoveComp;
	UPlayerAcidTeenDragonComponent DragonComp;
	UTeenDragonAirGlideComponent AirGlideComp;
	UTeenDragonAirGlideSettings AirGlideSettings;

	FHazeAcceleratedFloat AccRemainingInitialBoost;

	float CurrentAirBoost;
	float TimeStartedDescending = -1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		AirGlideComp = UTeenDragonAirGlideComponent::Get(Player);
		DragonComp = UPlayerAcidTeenDragonComponent::Get(Player);

		AirGlideSettings = UTeenDragonAirGlideSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(AirGlideComp.HasUpdatedGlideVerticalSpeedThisFrame())
			return false;

		if(!AirGlideComp.bIsAirGliding)
			return false;

		if(MoveComp.IsOnWalkableGround())
			return false;

		if(!AirGlideComp.bInitialAirBoostAvailable)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(AirGlideComp.HasUpdatedGlideVerticalSpeedThisFrame())
			return true;

		if(!AirGlideComp.bIsAirGliding)
			return true;

		if(MoveComp.IsOnWalkableGround())
			return true;

		if(!AirGlideComp.bInitialAirBoostAvailable)
			return true;

		if(Math::IsNearlyZero(AccRemainingInitialBoost.Value, 1.0))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CurrentAirBoost = 0;
		AHazeActor DragonActor = Cast<AHazeActor>(DragonComp.DragonMesh.Outer);

		UTeenDragonAirGlideEventHandler::Trigger_AirGlideActivated(Player);
		UDragonMovementAudioEventHandler::Trigger_AcidTeenGlideInitialUpwardsBoostTriggered(DragonActor);

		float AirBoost = AirGlideSettings.InitialAirBoostSize;
		float GlideVerticalSpeed = AirGlideComp.GetGlideVerticalSpeed(); 
		AirBoost += -GlideVerticalSpeed;
		AccRemainingInitialBoost.SnapTo(AirBoost);

		if(!DragonComp.bTopDownMode)
		{
			Player.ApplyCameraImpulse(AirGlideSettings.InitialAirBoostCameraImpulse, this);
			Player.PlayCameraShake(AirGlideComp.StartGlideCameraShake, this, 1.2);
		}
		
		Player.PlayForceFeedback(AirGlideComp.StartGlideForceFeedback, false, true, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AirGlideComp.bInitialAirBoostAvailable = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			float CurrentVerticalSpeed = AirGlideComp.GetGlideVerticalSpeed();

			float InitialAirBoostAcceleration = GetInitialAirBoost(DeltaTime);
			if (InitialAirBoostAcceleration > 0)
				CurrentAirBoost = InitialAirBoostAcceleration;
			else
			{
				CurrentAirBoost = Math::FInterpTo(CurrentAirBoost, InitialAirBoostAcceleration, DeltaTime, 3);
			}

			CurrentVerticalSpeed += CurrentAirBoost;
			float GravityAcceleration = AirGlideSettings.InitialAirBoostGravityAmount;
			if(CurrentVerticalSpeed > -AirGlideSettings.GlideMaxVerticalSpeed)
				CurrentVerticalSpeed -= GravityAcceleration * DeltaTime;
			AirGlideComp.SetGlideVerticalSpeed(CurrentVerticalSpeed);

			TEMPORAL_LOG(Player, "Air Glide").Page("Vertical Speed")
				.Value("Remaining Initial Boost", AccRemainingInitialBoost.Value)
				.Value("Initial Air Boost Acceleration", InitialAirBoostAcceleration)
				.Value("CurrentAirBoost", CurrentAirBoost)
				.Value("Gravity Acceleration", GravityAcceleration)
				.Status("Initial air boosting", FLinearColor::Purple)
			;
		}
	}

	float GetInitialAirBoost(float DeltaTime)
	{
		float AirBoost = 0.0;

		float PreAccelerationRemaining = AccRemainingInitialBoost.Value;
		AccRemainingInitialBoost.AccelerateTo(0.0, AirGlideSettings.InitialAirBoostApplicationDuration, DeltaTime);
		if(AirGlideComp.GetGlideVerticalSpeed() > AirGlideSettings.InitialAirBoostMaxVelocity)
		{
			return 0.0;
		}

		AirBoost = PreAccelerationRemaining - AccRemainingInitialBoost.Value;

		return AirBoost;
	}
};