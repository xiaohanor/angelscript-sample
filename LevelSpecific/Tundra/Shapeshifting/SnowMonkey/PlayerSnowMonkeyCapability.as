

class UTundraPlayerSnowMonkeyCapability : UTundraShapeShiftingCapabilityBase
{
	default ShapeType = ETundraShapeshiftShape::Big;

	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkey);
	default CapabilityTags.Add(BlockedWhileIn::GrappleEnter);

	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::Swing);

	UTundraPlayerSnowMonkeyComponent SnowMonkeyComp;
	UPlayerLedgeGrabComponent LedgeGrabComp;
	UPlayerMovementComponent MoveComp;
	UPlayerPoleClimbComponent PoleClimbComp;
	UTundraPlayerSnowMonkeySettings GorillaSettings;
	UTundraPlayerShapeshiftingSettings ShapeshiftingSettings;

	UFUNCTION(BlueprintOverride)
	void Setup() override
	{
		Super::Setup();
		SnowMonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		GorillaSettings = UTundraPlayerSnowMonkeySettings ::GetSettings(Player);
		ShapeshiftingSettings = UTundraPlayerShapeshiftingSettings::GetSettings(Player);
		LedgeGrabComp = UPlayerLedgeGrabComponent::Get(Player);
		PoleClimbComp = UPlayerPoleClimbComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::ShapeShiftForm, this);

		SnowMonkeyComp.bIsActive = true;
		ShapeshiftingComponent.ReleaseGrappleAndSwing();
		SnowMonkeyComp.TimeOfTurnIntoSnowMonkey = Time::GetGameTimeSeconds();

		// Camera
		if(SnowMonkeyComp.CameraSettings != nullptr)
		{
			Player.ApplyCameraSettings(SnowMonkeyComp.CameraSettings, 2, this, SubPriority = 60);
		}
		
		// Effect
		if(ShapeshiftingComponent.ShouldUseActivationEffect())
		{
			FTundraPlayerSnowMonkeyTransformParams Params;
			Params.MorphTime = ShapeshiftingSettings.MorphTime;
			UTundraPlayerSnowMonkeyEffectHandler::Trigger_OnTransformedInto(SnowMonkeyComp.SnowMonkeyActor, Params);
		}

		// Movement
		Player.ApplySettings(SnowMonkeyComp.FloorMotionSettings, this);
		Player.ApplySettings(SnowMonkeyComp.AirMotionSettings, this);
		Player.ApplySettings(SnowMonkeyComp.SprintSettings, this);
		Player.ApplySettings(SnowMonkeyComp.PoleClimbSettings, this);
		Player.ApplySettings(SnowMonkeyComp.LedgeGrabSettings, this);
		Player.ApplySettings(SnowMonkeyComp.SlideJumpSettings, this);
		Player.ApplySettings(SnowMonkeyComp.PerchSettings, this);
		Player.ApplySettings(SnowMonkeyComp.BossPunchSettings, this);
		UPlayerJumpSettings::SetImpulse(Player, GorillaSettings.JumpImpulse, this);
		UPlayerJumpSettings::SetPerchImpulse(Player, GorillaSettings.JumpImpulse * 0.5, this);
		UPlayerJumpSettings::SetFacingDirectionInterpSpeed(Player, SnowMonkeyComp.AirMotionSettings.MaximumTurnRate, this);
		UPlayerJumpSettings::SetHorizontalPerchImpulseMultiplier(Player, 0.8, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::ShapeShiftForm, this);

		SnowMonkeyComp.bIsActive = false;

		// We have to call effects before clearing shape since that stops the sheet and removes the effect handler
		if(ShapeshiftingComponent.ShouldUseActivationEffect() || IsBlocked())
		{
			FTundraPlayerSnowMonkeyTransformParams Params;
			Params.MorphTime = ShapeshiftingSettings.MorphTime;
			UTundraPlayerSnowMonkeyEffectHandler::Trigger_OnTransformedOutOf(SnowMonkeyComp.SnowMonkeyActor, Params);
		}

		ShapeshiftingComponent.ClearShape(ETundraShapeshiftShape::Big);

		SnowMonkeyComp.TimeOfTurnIntoSnowMonkey = -100.0;
		
		Player.ClearCameraSettingsByInstigator(this, OverrideBlendTime = 3);
		Player.ClearSettingsByInstigator(this);
	}
};