class UTeenDragonAirGlideCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonAirGlide);
	default CapabilityTags.Add(CapabilityTags::StickInput);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::Gameplay;

	UCameraUserComponent CameraUser;
	UPlayerAcidTeenDragonComponent AcidDragonComp;
	UTeenDragonAirGlideComponent AirGlideComp;
	UHazeMovementComponent DragonMoveComp;

	FVector CurrentYawAxis;
	UTeenDragonAirGlideSettings AirGlideSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AcidDragonComp = UPlayerAcidTeenDragonComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
		DragonMoveComp = UHazeMovementComponent::Get(Player);
		AirGlideComp = UTeenDragonAirGlideComponent::Get(Player);
		AirGlideSettings = UTeenDragonAirGlideSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!AirGlideComp.bIsAirGliding && !AirGlideComp.bInAirCurrent)
			return false;

		if(AcidDragonComp.bTopDownMode)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!AirGlideComp.bIsAirGliding && !AirGlideComp.bInAirCurrent)
			return true;

		if(AcidDragonComp.bTopDownMode)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		Player.ApplyCameraSettings(AirGlideComp.HoverCamSettings, AirGlideSettings.HoverCameraSettingsBlendInTime, this, SubPriority = 60);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		Player.ClearCameraSettingsByInstigator(this, AirGlideSettings.HoverCameraSettingsBlendOutTime);
		Player.StopCameraShakeByInstigator(this);

		SpeedEffect::ClearSpeedEffect(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float SpeedAlpha = Math::NormalizeToRange(Player.ActorHorizontalVelocity.Size(), 0, AirGlideSettings.GlideHorizontalMaxMoveSpeed);
		Player.ApplyManualFractionToCameraSettings(AirGlideSettings.FOVSpeedScale.GetFloatValue(SpeedAlpha), this);

		Player.PlayCameraShake(AirGlideComp.ContinuousGlideCameraShake, this, AirGlideSettings.CameraShakeScale.GetFloatValue(SpeedAlpha));

		float SpeedEffectValue = AirGlideSettings.SpeedEffectValue.GetFloatValue(SpeedAlpha);
		if(SpeedEffectValue <= KINDA_SMALL_NUMBER)
			SpeedEffect::ClearSpeedEffect(Player, this);
		else
			SpeedEffect::RequestSpeedEffect(Player, SpeedEffectValue, this, EInstigatePriority::Normal);

		TEMPORAL_LOG(Player, "Air Glide")
			.Value("Air Glide Camera: Speed Effect Value", SpeedEffectValue)
		;
	}
};