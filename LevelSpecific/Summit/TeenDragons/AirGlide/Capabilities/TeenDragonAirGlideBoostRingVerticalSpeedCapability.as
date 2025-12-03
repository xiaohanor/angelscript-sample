class UTeenDragonAirGlideBoostRingVerticalSpeedCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonAirGlide);

	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 35;

	UPlayerAcidTeenDragonComponent DragonComp;
	UTeenDragonAirGlideComponent AirGlideComp;
	UTeenDragonAirGlideSettings AirGlideSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AirGlideComp = UTeenDragonAirGlideComponent::Get(Player);
		DragonComp = UPlayerAcidTeenDragonComponent::Get(Player);

		AirGlideSettings = UTeenDragonAirGlideSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!AirGlideComp.bIsAirGliding)
			return false;

		if(AirGlideComp.HasUpdatedGlideVerticalSpeedThisFrame())
			return false;

		/** Going upwards */
		if(AirGlideComp.GetGlideVerticalSpeed() > 0)
			return false;

		if(!AirGlideComp.ActiveRingParams.IsSet())
			return false;
		
		auto RingParams = AirGlideComp.ActiveRingParams.Value;
		if(!RingParams.bStopDownwardsSpeed)
			return false;

		if(RingParams.BoostTimer > RingParams.DownwardsSpeedStopDuration)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!AirGlideComp.bIsAirGliding)
			return true;

		if(AirGlideComp.HasUpdatedGlideVerticalSpeedThisFrame())
			return true;

		/** Going upwards */
		if(AirGlideComp.GetGlideVerticalSpeed() > 0)
			return true;

		if(!AirGlideComp.ActiveRingParams.IsSet())
			return true;

		auto RingParams = AirGlideComp.ActiveRingParams.Value;
		if(!RingParams.bStopDownwardsSpeed)
			return true;

		if(RingParams.BoostTimer > RingParams.DownwardsSpeedStopDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			float CurrentVerticalSpeed = AirGlideComp.GetGlideVerticalSpeed();
			auto RingParams = AirGlideComp.ActiveRingParams.Value;
			CurrentVerticalSpeed = Math::FInterpTo(CurrentVerticalSpeed, 0, DeltaTime, RingParams.DownwardsSpeedStopAcceleration);
			AirGlideComp.SetGlideVerticalSpeed(CurrentVerticalSpeed);

			TEMPORAL_LOG(Player, "Air Glide").Page("Vertical Speed")
				.Status("Boost Ring Vertical Speed", FLinearColor::LucBlue)
			;
		}
	}

};