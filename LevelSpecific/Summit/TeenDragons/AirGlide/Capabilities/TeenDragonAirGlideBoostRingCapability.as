class UTeenDragonAirGlideBoostRingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonAirGlide);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

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
	bool ShouldActivate(FSummitAirGlideBoostRingParams& Params) const
	{
		if(!AirGlideComp.ActiveRingParams.IsSet())
			return false;

		Params = AirGlideComp.ActiveRingParams.Value;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		auto Boost = AirGlideComp.ActiveRingParams.Value;
		if(Boost.BoostTimer >= Boost.BoostDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSummitAirGlideBoostRingParams Params)
	{
		Player.ApplyCameraSettings(AirGlideComp.RingBoostCamSettings, Params.BoostDuration, this, SubPriority = 62);
		Player.PlayCameraShake(AirGlideComp.RingBoostStartCameraShake, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AirGlideComp.ActiveRingParams.Reset();
		Player.ClearCameraSettingsByInstigator(this, 4.0);
		UTeenDragonAirGlideEventHandler::Trigger_BoostRingStopped(Player);
		UDragonMovementAudioEventHandler::Trigger_AcidTeenBoostRingStop(DragonComp.GetTeenDragon());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			AirGlideComp.BoostRingSpeed = GetRingBoostSpeed(DeltaTime);
		}
	}

	float GetRingBoostSpeed(float DeltaTime)
	{
		float BoostSpeed = 0.0;

		auto& Boost = AirGlideComp.ActiveRingParams.Value;

		float BoostAlpha = Boost.BoostTimer / Boost.BoostDuration;
		BoostSpeed += Boost.MaxBoostSpeed * Boost.BoostCurve.GetFloatValue(BoostAlpha); 

		Boost.BoostTimer += DeltaTime;
		return BoostSpeed;
	}

};