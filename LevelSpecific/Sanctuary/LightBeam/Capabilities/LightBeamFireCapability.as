class ULightBeamFireCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(LightBeam::Tags::LightBeam);
	default CapabilityTags.Add(LightBeam::Tags::LightBeamFire);

	default TickGroupOrder = 100;

	ULightBeamUserComponent UserComp;
	UPlayerAimingComponent AimComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = ULightBeamUserComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WasActionStarted(ActionNames::SecondaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (WasActionStopped(ActionNames::SecondaryLevelAbility))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FAimingSettings AimSettings;
		AimSettings.bShowCrosshair = true;
		AimSettings.OverrideAutoAimTarget = ULightBeamTargetComponent;

		AimComp.StartAiming(UserComp, AimSettings);
		UserComp.StartFiring();

		Player.BlockCapabilities(LightProjectile::Tags::LightProjectile, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UserComp.StopFiring();
		AimComp.StopAiming(UserComp);

		Player.UnblockCapabilities(LightProjectile::Tags::LightProjectile, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto AimResult = AimComp.GetAimingTarget(UserComp);

		const FVector TraceStart = Math::ClosestPointOnInfiniteLine(
			AimResult.AimOrigin,
			AimResult.AimOrigin + (AimResult.AimDirection * LightBeam::BeamLength),
			Player.ActorCenterLocation
		);
		const FVector TraceEnd = TraceStart + (AimResult.AimDirection * LightBeam::BeamLength);

		UserComp.UpdateHits(TraceStart, TraceEnd);
	}
}