class UTundraPlayerTreeGuardianCapability : UTundraShapeShiftingCapabilityBase
{
	default ShapeType = ETundraShapeshiftShape::Big;

	default CapabilityTags.Add(TundraShapeshiftingTags::TreeGuardian);

	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);

	UPlayerTargetablesComponent PlayerTargetablesComponent;
	UTundraPlayerTreeGuardianComponent TreeGuardianComp;
	USkeletalMesh OldSkeletalMesh;
	UTundraPlayerTreeGuardianSettings Settings;
	UTundraPlayerShapeshiftingSettings ShapeshiftingSettings;

	UFUNCTION(BlueprintOverride)
	void Setup() override
	{
		Super::Setup();

		TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Player);
		PlayerTargetablesComponent = UPlayerTargetablesComponent::Get(Player);
		Settings = UTundraPlayerTreeGuardianSettings::GetSettings(Player);
		ShapeshiftingSettings = UTundraPlayerShapeshiftingSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::ShapeShiftForm, this);

		ShapeshiftingComponent.ReleaseGrappleAndSwing();

		TreeGuardianComp.bIsActive = true;

		if(TreeGuardianComp.CameraSettings != nullptr)
		{
			Player.ApplyCameraSettings(TreeGuardianComp.CameraSettings, 2, this, SubPriority = 60);
		}

		if(ShapeshiftingComponent.ShouldUseActivationEffect())
		{
			FTundraPlayerTreeGuardianTransformParams Params;
			Params.MorphTime = ShapeshiftingSettings.MorphTime;
			UTreeGuardianBaseEffectEventHandler::Trigger_OnTransformedInto(TreeGuardianComp.TreeGuardianActor, Params);
			UTreeGuardianBaseEffectEventHandler::Trigger_OnTransformedInto(Owner, Params);
			UTreeGuardianBaseEffectEventHandler::Trigger_OnTransformedInto(Owner, FTundraPlayerTreeGuardianTransformParams());
		}

		Player.ApplySettings(TreeGuardianComp.SteppingSettings, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::ShapeShiftForm, this);

		// We have to call effects before clearing shape since that stops the sheet and removes the effect handler
		if(ShapeshiftingComponent.ShouldUseActivationEffect() || IsBlocked())
		{
			FTundraPlayerTreeGuardianTransformParams Params;
			Params.MorphTime = ShapeshiftingSettings.MorphTime;
			UTreeGuardianBaseEffectEventHandler::Trigger_OnTransformedOutOf(TreeGuardianComp.TreeGuardianActor, Params);
			UTreeGuardianBaseEffectEventHandler::Trigger_OnTransformedOutOf(Owner, Params);
		}

		// Force out of ranged interactions (in IceKing the ranged interaction capabilities are added in all shapes but when shapeshifting out of TreeGuardian they should still be blocked!)
		Player.BlockCapabilities(TundraRangedInteractionTags::RangedInteractionInteraction, this);
		Player.UnblockCapabilities(TundraRangedInteractionTags::RangedInteractionInteraction, this);

		ShapeshiftingComponent.ClearShape(ETundraShapeshiftShape::Big);
		
		TreeGuardianComp.bIsActive = false;
		Player.ClearCameraSettingsByInstigator(this);

		Player.ClearSettingsByInstigator(this);
	}
}