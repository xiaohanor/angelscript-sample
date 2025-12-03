class UTeenDragonAirGlideGravityCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonAirGlide);

	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 50;

	FHazeAcceleratedFloat AccVerticalSpeed;

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
		if(AirGlideComp.HasUpdatedGlideVerticalSpeedThisFrame())
			return false;

		if(!AirGlideComp.bIsAirGliding)
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

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccVerticalSpeed.SnapTo(AirGlideComp.GetGlideVerticalSpeed());
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
			float TargetVerticalSpeed = -AirGlideSettings.GlideMaxVerticalSpeed;
			AccVerticalSpeed.AccelerateTo(TargetVerticalSpeed, AirGlideSettings.VerticalVelocityAccelerationDuration, DeltaTime);
			AirGlideComp.SetGlideVerticalSpeed(AccVerticalSpeed.Value);

			TEMPORAL_LOG(Player, "Air Glide").Page("Vertical Speed")
				.Status("Gravity", FLinearColor::Black)
				.Value("Gravity Acc Vertical Speed", AccVerticalSpeed.Value)
			;
		}
	}
};