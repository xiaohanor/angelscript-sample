class UTeenDragonAirGlideVerticalOverSpeedCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonAirGlide);

	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 45;

	UPlayerAcidTeenDragonComponent DragonComp;
	UTeenDragonAirGlideComponent AirGlideComp;
	UTeenDragonAirGlideSettings AirGlideSettings;

	const float InitialVelocityOverTerminalInterpSpeed = 3.0;

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
		if(AirGlideComp.HasUpdatedGlideVerticalSpeedThisFrame())
			return false;

		if(!AirGlideComp.bIsAirGliding)
			return false;

		if(AirGlideComp.GetGlideVerticalSpeed() > -AirGlideSettings.GlideMaxVerticalSpeed)
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

		if(AirGlideComp.GetGlideVerticalSpeed() > -AirGlideSettings.GlideMaxVerticalSpeed)
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
			float TargetVerticalSpeed = -AirGlideSettings.GlideMaxVerticalSpeed + 10.0;
			CurrentVerticalSpeed = Math::FInterpTo(CurrentVerticalSpeed, TargetVerticalSpeed, DeltaTime, InitialVelocityOverTerminalInterpSpeed);
			AirGlideComp.SetGlideVerticalSpeed(CurrentVerticalSpeed);

			TEMPORAL_LOG(Player, "Air Glide").Page("Vertical Speed")
				.Status("Vertical Over Speed", FLinearColor::Gray)
			;
		}
	}
};