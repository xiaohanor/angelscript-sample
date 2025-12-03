
class UTundraPlayerOtterCapability : UTundraShapeShiftingCapabilityBase
{
	default ShapeType = ETundraShapeshiftShape::Small;

	default CapabilityTags.Add(TundraShapeshiftingTags::Otter);

	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);

	UTundraPlayerOtterComponent OtterComp;
	UTundraPlayerShapeshiftingSettings ShapeshiftingSettings;
	UTundraPlayerOtterSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup() override
	{
		Super::Setup();
		OtterComp = UTundraPlayerOtterComponent::Get(Player);
		ShapeshiftingSettings = UTundraPlayerShapeshiftingSettings::GetSettings(Player);
		Settings = UTundraPlayerOtterSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::ShapeShiftForm, this);

		ShapeshiftingComponent.ReleaseGrappleAndSwing();
		
		Player.ApplySettings(OtterComp.SwimSettings, this);
		Player.ApplySettings(OtterComp.FloorMotionSettings, this);
		Player.ApplySettings(OtterComp.JumpSettings, this);

		// Camera
		if(OtterComp.CameraSettings != nullptr)
		{
			Player.ApplyCameraSettings(OtterComp.CameraSettings, 2, this, SubPriority = 50);
		}
		
		// Effect
		if(ShapeshiftingComponent.ShouldUseActivationEffect())
		{
			FTundraPlayerOtterTransformParams Params;
			Params.MorphTime = ShapeshiftingSettings.MorphTime;
			UTundraPlayerOtterEffectHandler::Trigger_OnTransformedInto(OtterComp.OtterActor, Params);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::ShapeShiftForm, this);

		// We have to call effects before clearing shape since that stops the sheet and removes the effect handler
		if(ShapeshiftingComponent.ShouldUseActivationEffect() || IsBlocked())
		{
			FTundraPlayerOtterTransformParams Params;
			Params.MorphTime = ShapeshiftingSettings.MorphTime;
			UTundraPlayerOtterEffectHandler::Trigger_OnTransformedOutOf(OtterComp.OtterActor, Params);
		}

		ShapeshiftingComponent.ClearShape(ETundraShapeshiftShape::Small);
		
		Player.ClearCameraSettingsByInstigator(this);
		Player.ClearSettingsByInstigator(this);
	}
};