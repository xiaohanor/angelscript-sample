class USkylineFlyingCarRifleAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(FlyingCarTags::FlyingCarGunner);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::LastMovement;

	USkylineFlyingCarGunnerComponent GunnerComponent;
	UPlayerAimingComponent AimingComponent;
	UPlayerTargetablesComponent TargetablesComponent;

	UHazeUserWidget ReticleWidget;
	UHazeUserWidget CrosshairWidget;

	UCameraSettings CameraSettings;

	// Proper aiming zone, anything above this will move faster (-value to value)
	const float AimZoneDegrees = 30.0;
	const float FastZoneSensitivityFactor = 1.85;

	float SensitivityFactorYaw = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GunnerComponent = USkylineFlyingCarGunnerComponent::Get(Owner);
		AimingComponent = UPlayerAimingComponent::Get(Owner);
		TargetablesComponent = UPlayerTargetablesComponent::Get(Owner);
		CameraSettings = UCameraSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (GunnerComponent.Car == nullptr)
			return false;

		if (GunnerComponent.GetGunnerState() != EFlyingCarGunnerState::Rifle)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (GunnerComponent.Car == nullptr)
			return true;

		if (GunnerComponent.GetGunnerState() != EFlyingCarGunnerState::Rifle)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// We don't want crosshair to follow target
		FAimingSettings Settings;
		Settings.OverrideCrosshairWidget = GunnerComponent.RifleWidgetData.CrosshairWidget;
		Settings.bShowCrosshair = true;
		Settings.bUseAutoAim = true;
		Settings.bCrosshairFollowsTarget = false;
		Settings.OverrideAutoAimTarget = USkylineFlyingCarRifleTargetableComponent;
		Settings.CrosshairLingerDuration = 0.0;
		AimingComponent.StartAiming(this, Settings);

		// Display weapon
		GunnerComponent.Rifle.SetActorHiddenInGame(false);
		GunnerComponent.FakeRifleMeshComponent.SetHiddenInGame(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimingComponent.StopAiming(this);

		Player.RemoveWidget(ReticleWidget);
		ReticleWidget = nullptr;

		GunnerComponent.Rifle.SetActorHiddenInGame(true);
		GunnerComponent.FakeRifleMeshComponent.SetHiddenInGame(true);

		CameraSettings.SensitivityFactorYaw.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Camera speed
		float FrontalAlignment = Math::RadiansToDegrees(Math::Acos(Math::Abs(Player.ControlRotation.Vector().DotProduct(GunnerComponent.Car.ActorForwardVector))));
		float TargetValue = FrontalAlignment > AimZoneDegrees ? FastZoneSensitivityFactor : 1.0;
		SensitivityFactorYaw = Math::FInterpTo(SensitivityFactorYaw, TargetValue, DeltaTime, 5);
		CameraSettings.SensitivityFactorYaw.Apply(TargetValue, this, 0.0);

		TargetablesComponent.ShowWidgetsForTargetables(USkylineFlyingCarRifleTargetableComponent);

		GunnerComponent.UpdateBlendSpaceValues();

		// Animate!
		if (Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(n"FlyingCarGunnerRifle", this);
	}
}