class ULightBeamStrafeCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(LightBeam::Tags::LightBeam);
	default CapabilityTags.Add(LightBeam::Tags::LightBeamStrafe);

	default TickGroupOrder = 80;

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
		if (!AimComp.IsAiming(UserComp))
			return false;

		if (AimComp.HasAiming2DConstraint())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!AimComp.IsAiming(UserComp))
			return true;

		if (AimComp.HasAiming2DConstraint())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.EnableStrafe(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DisableStrafe(this);
	}
}