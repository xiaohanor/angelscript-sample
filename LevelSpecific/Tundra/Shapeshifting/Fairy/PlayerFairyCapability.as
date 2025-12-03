class UTundraPlayerFairyCapability : UTundraShapeShiftingCapabilityBase
{
	default ShapeType = ETundraShapeshiftShape::Small;

	default CapabilityTags.Add(TundraShapeshiftingTags::Fairy);

	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);

	UTundraPlayerFairyComponent FairyComp;
	UPlayerMovementComponent MoveComp;
	UPlayerPoleClimbComponent PoleClimbComp;
	UTundraPlayerFairySettings Settings;
	UTundraPlayerShapeshiftingSettings ShapeshiftingSettings;

	UFUNCTION(BlueprintOverride)
	void Setup() override
	{
		Super::Setup();
		FairyComp = UTundraPlayerFairyComponent::Get(Player);
		Settings = UTundraPlayerFairySettings::GetSettings(Player);
		ShapeshiftingSettings = UTundraPlayerShapeshiftingSettings::GetSettings(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		PoleClimbComp = UPlayerPoleClimbComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(BlockedWhileIn::ShapeShiftForm, this);

		ShapeshiftingComponent.ReleaseGrappleAndSwing();
			
		if(!MoveComp.HasGroundContact() && MoveComp.VerticalSpeed < Settings.MaxVerticalVelocityToLeapAfterShapeshift)
			FairyComp.bFairyLeapAfterShapeshifting = true;
	
		FairyComp.bIsActive = true;

		if(FairyComp.CameraSettings != nullptr)
		{
			Player.ApplyCameraSettings(FairyComp.CameraSettings, 2, this, SubPriority = 60);
		}

		Player.ApplySettings(FairyComp.PoleClimbSettings, this);
		Player.ApplySettings(FairyComp.FloorMotionSettings, this);
		Player.ApplySettings(FairyComp.CrouchSettings, this);
		Player.ApplySettings(FairyComp.FloorSlowdownSettings, this);

		if(ShapeshiftingComponent.ShouldUseActivationEffect())
		{
			FTundraPlayerFairyTransformParams Params;
			Params.MorphTime = ShapeshiftingSettings.MorphTime;
			UTundraPlayerFairyEffectHandler::Trigger_OnTransformedInto(FairyComp.FairyActor, Params);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(BlockedWhileIn::ShapeShiftForm, this);

		// We have to call effects before clearing shape since that stops the sheet and removes the effect handler
		if(ShapeshiftingComponent.ShouldUseActivationEffect() || IsBlocked())
		{
			FTundraPlayerFairyTransformParams Params;
			Params.MorphTime = ShapeshiftingSettings.MorphTime;
			UTundraPlayerFairyEffectHandler::Trigger_OnTransformedOutOf(FairyComp.FairyActor, Params);
		}

		Player.ClearSettingsByInstigator(this);
		ShapeshiftingComponent.ClearShape(ETundraShapeshiftShape::Small);
		
		FairyComp.bIsActive = false;
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(PoleClimbComp.PoleType == EPoleType::Slippery)
		{
			FVector DebugLocation = Player.ActorLocation;
			DebugLocation += FVector::UpVector * Player.CapsuleComponent.ScaledCapsuleHalfHeight * 2;
			float Alpha = (Math::Sin(Time::GameTimeSeconds * 20) + 1) * 0.5;
			Debug::DrawDebugString(DebugLocation, "!", FLinearColor::Red, 0, Math::Lerp(2, 4, Alpha));
		}
	}
}