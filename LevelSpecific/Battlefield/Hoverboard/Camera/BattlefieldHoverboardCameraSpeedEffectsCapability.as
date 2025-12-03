class UBattlefieldHoverboardCameraSpeedEffectsCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CameraTags::Camera);

   	default DebugCategory = n"Hoverboard";

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 1;

	UBattlefieldHoverboardComponent HoverboardComp;
	UPlayerMovementComponent MoveComp;
	UCameraUserComponent CameraUser;

	UBattlefieldHoverboardCameraControlSettings CameraControlSettings;

	FHazeAcceleratedFloat AccSpeedAlpha;

	const float SpeedAlphaAccelerationDuration = 0.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverboardComp = UBattlefieldHoverboardComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);

		CameraControlSettings = UBattlefieldHoverboardCameraControlSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HoverboardComp.bCanRunSpeedEffect)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!HoverboardComp.bCanRunSpeedEffect)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplyCameraSettings(CameraControlSettings.CameraSpeedSettings, 0.0, this);
		AccSpeedAlpha.SnapTo(0.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this);
		SpeedEffect::ClearSpeedEffect(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float CurrentSpeed = Player.ActorHorizontalVelocity.Size();
		float SpeedAlphaTarget = Math::GetPercentageBetweenClamped(CameraControlSettings.MinSpeedEffectSpeed, CameraControlSettings.MaxSpeedEffectSpeed, CurrentSpeed);
		AccSpeedAlpha.AccelerateTo(SpeedAlphaTarget, SpeedAlphaAccelerationDuration, DeltaTime);

		TEMPORAL_LOG(HoverboardComp)
			.Value("Camera Speed Alpha Target", SpeedAlphaTarget)
			.Value("Camera Acc Speed Alpha", AccSpeedAlpha.Value)
		;
			
		Player.ApplyManualFractionToCameraSettings(AccSpeedAlpha.Value, this);

		float SpeedEffectValue = CameraControlSettings.SpeedEffectCurve.GetFloatValue(AccSpeedAlpha.Value);
		if(Math::IsNearlyZero(SpeedEffectValue, 0.05))
			SpeedEffect::ClearSpeedEffect(Player, this);
		else
			SpeedEffect::RequestSpeedEffect(Player, SpeedEffectValue, this, EInstigatePriority::Normal);
			
	}
};