class USkippingStonesCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	USkippingStonesPlayerComponent PlayerComp;
	UCameraUserComponent CameraUser;
	UCameraSettings CameraSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		PlayerComp = USkippingStonesPlayerComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
		CameraSettings = UCameraSettings::GetSettings(Player);
	}

	bool SupportsInteraction(UInteractionComponent CheckInteraction) const override
	{
		if(!CheckInteraction.Owner.IsA(ASkippingStones))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		auto SkippingStones = Cast<ASkippingStones>(Params.Interaction.Owner);
		check(SkippingStones != nullptr);
		PlayerComp.SkippingStonesInteraction = SkippingStones;

		USkippingStonesPlayerEventHandler::Trigger_OnEnter(Player);

		PlayerComp.State = ESkippingStonesState::Pickup;

		Player.ApplyCameraSettings(PlayerComp.CameraSettings, 4, this);
		//PlayerComp.ChargeWidget = Cast<USkippingStonesChargeWidget>(Player.AddWidget(PlayerComp.ChargeWidgetClass));

		FHazeCameraClampSettings ClampSettings(SkippingStones::YawClampAngle, SkippingStones::PitchClampAngle);
		CameraSettings.Clamps.Apply(ClampSettings, this, 1, EHazeCameraPriority::High);

		FHazePointOfInterestFocusTargetInfo POI;
		POI.SetFocusToWorldLocation(SkippingStones.ActorTransform.TransformPosition(FVector(1000, 0, 100)));

		FApplyPointOfInterestSettings POISettings;
		POISettings.Duration = 0.5;
		POISettings.InputSuspension.bUseInputSuspension = true;
		Player.ApplyPointOfInterest(this, POI, POISettings);
		Player.BlockCapabilities(CapabilityTags::FindOtherPlayer, this);
		Player.BlockCapabilities(CapabilityTags::OtherPlayerIndicator, this);

		CameraUser.SetAiming(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		USkippingStonesPlayerEventHandler::Trigger_OnExit(Player);

		Player.ClearCameraSettingsByInstigator(this, 2);
		//Player.RemoveWidget(PlayerComp.ChargeWidget);
		CameraSettings.Clamps.Clear(this);
		Player.ClearPointOfInterestByInstigator(this);
		CameraUser.ClearAiming(this);

		Player.UnblockCapabilities(CapabilityTags::FindOtherPlayer, this);
		Player.UnblockCapabilities(CapabilityTags::OtherPlayerIndicator, this);

		// Reset all state
		PlayerComp.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!Player.Mesh.CanRequestLocomotion())
			return;

		Player.Mesh.RequestLocomotion(n"SkippingStones", this);
	}
};